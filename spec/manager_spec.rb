# frozen_string_literal: true

require "date"
require "json"
require "manager"

describe Manager do
  before do
    @fake_octokit = double :octokit
    @fake_api_connection = double
    @fake_log_creator = double :log_creator
    allow(@fake_octokit).to receive(:new)
    allow(@fake_api_connection).to receive(:new).and_return @fake_octokit
    allow(@fake_log_creator).to receive(:new).and_return @fake_log_creator

    @manager = Manager.new(client: @fake_octokit,
                           api_connection: @fake_api_connection,
                           log_creator: @fake_log_creator)

    @fake_env = {}
    allow(ENV).to receive(:[]) do |key|
      @fake_env[key] || raise("#{key} not expected")
    end
  end

  it "calls the appropriate method based on input operation" do
    @fake_env["INPUT_OPERATION"] = "prepare for release"
    expect(@manager).to receive :prepare_for_release
    @manager.do_operation

    @fake_env["INPUT_OPERATION"] = "github"
    expect(@manager).to receive :github_release_notes
    @manager.do_operation

    @fake_env["INPUT_OPERATION"] = "hello"
    expected = "Unexpected string input. 'hello' is not a valid operation. Exiting action.\n"
    expect { @manager.do_operation }.to output(/#{Regexp.quote(expected)}/).to_stdout
  end

  describe "with 'prepare for release'" do
    before do
      @fake_env["INPUT_OPERATION"] = "prepare for release"
      @fake_env["GITHUB_EVENT_NAME"] = "pull_request"
      @fake_env["GITHUB_BASE_REF"] = "main"
      @fake_env["GITHUB_REF_NAME"] = "78/merge"
    end

    it "does nothing if not a PR" do
      @fake_env["GITHUB_EVENT_NAME"] = "push"
      expect(@manager).not_to receive :commits_data_for_log

      @manager.do_operation
    end

    it "does nothing if not the right PR branches" do
      @fake_env["GITHUB_BASE_REF"] = "release/0.1.0"
      @fake_env["GITHUB_HEAD_REF"] = "issue/99-red_balloons"

      expect(@manager).not_to receive :commits_data_for_log

      @manager.do_operation
    end

    it "creates and commits a new changelog given the right branches" do
      @fake_env["GITHUB_HEAD_REF"] = "release/1.7"
      allow(Date).to receive(:today).and_return(Date.new(2022, 5, 5))

      fake_commits = [{ commit: { message: "Complete work (close #5)" } }]

      useful_commit_data = [
        { message: "Choose HTTP response codes not to retry",
          issue: "316",
          author: "mscwilson",
          snowplower: true,
          breaking_change: true,
          type: "feature" },
        { message: "Allow Emitter to use a custom ExecutorService",
          issue: "278",
          author: "AcidFlow",
          snowplower: false,
          breaking_change: false,
          type: "bug" }
      ]

      old_log = { sha: "12345",
                  contents: "Version 0.2.0 (2022-02-01)\n-----------------------"\
                            "\nPublish Gradle module file with bintrayUpload (#255)"\
                            "\nUpdate snyk integration to include project name in "\
                            "GitHub action (#8) - thanks @SomeoneElse!\n" }

      new_log = "Version 1.7.0 (2022-05-05)\n-----------------------"\
                "\nChoose HTTP response codes not to retry (#316)"\
                "\nAllow Emitter to use a custom ExecutorService (#278) - thanks @AcidFlow!\n\n"\
                "Version 0.2.0 (2022-02-01)\n-----------------------"\
                "\nPublish Gradle module file with bintrayUpload (#255)"\
                "\nUpdate snyk integration to include project name in GitHub action (#8) - thanks @SomeoneElse!\n"

      allow(@fake_octokit).to receive(:commits_from_pr).with(number: 78)
      allow(@fake_log_creator).to receive(:relevant_commits).and_return fake_commits
      allow(@fake_log_creator).to receive(:useful_commit_data).and_return useful_commit_data
      allow(@fake_octokit).to receive(:file).and_return old_log
      allow(@fake_log_creator).to receive(:new_changelog_text).and_return new_log

      expect(@manager).to receive(:commit_files).with("1.7.0", new_log, "12345")
      @manager.do_operation
    end

    it "quits early if the last commit was already 'Prepare for {this} release'" do
      @fake_env["GITHUB_HEAD_REF"] = "release/2.5.3"

      message = "Did this action already run? There's a 'Prepare for 2.5.3 release' commit right there."
      fake_commits = [{ commit: { message: "Prepare for 2.5.3 release" } }]

      allow(@fake_octokit).to receive(:commits_from_pr).with(number: 78)
      allow(@fake_log_creator).to receive(:relevant_commits).and_return(fake_commits)

      expect(@fake_log_creator).not_to receive(:useful_commit_data)
      expect(@manager).not_to receive(:old_changelog_data)
      expect { @manager.do_operation }.to output(/#{Regexp.quote(message)}/).to_stdout
    end

    it "doesn't do anything with versions if no locations file is provided" do
      @fake_env["INPUT_VERSION_SCRIPT_PATH"] = nil
      expect(@manager).not_to receive(:version_files_tree)
    end

    xit "finds where version strings are if locations file is provided" do
      @fake_env["INPUT_VERSION_SCRIPT_PATH"] = "version_locations.json"
      file = JSON.parse(File.read("version_locations.json"))

      expect(@manager.find_version_strings).to eq file
    end
  end

  describe "with 'github release notes'" do
    before do
      @fake_env["INPUT_OPERATION"] = "github release notes"
      @fake_env["GITHUB_REF_NAME"] = "3.2.1"
    end

    it "does nothing if not a tag event" do
      @fake_env["GITHUB_REF_TYPE"] = "push"

      expect(@manager).not_to receive :commits_data_for_release_notes
      @manager.do_operation
    end

    it "outputs encoded release notes" do
      @fake_env["GITHUB_REF_TYPE"] = "tag"

      fake_pr = { base: { ref: "main" }, body: "We are pleased to announce this release." }
      fake_commits = ["not an empty array"]
      formatted_commits = "**New features**\nAdd pause and resume to EmitterController (#672)\n"

      expected_output = "V2UgYXJlIHBsZWFzZWQgdG8gYW5ub3VuY2UgdGhpcyByZ"\
                        "WxlYXNlLgoKKipOZXcgZmVhdHVyZXMqKgpBZGQgcGF1c2"\
                        "UgYW5kIHJlc3VtZSB0byBFbWl0dGVyQ29udHJvbGxlciAoIzY3MikK"

      allow(@fake_octokit).to receive(:pr_from_title).and_return(fake_pr)
      allow(@fake_octokit).to receive(:commits_from_branch)
      allow(@fake_log_creator).to receive(:relevant_commits)
      allow(@fake_log_creator).to receive(:useful_commit_data).and_return(fake_commits)
      allow(@fake_log_creator).to receive(:fancy_changelog).and_return(formatted_commits)

      expect { @manager.do_operation }.to output(/#{Regexp.quote(expected_output)}/).to_stdout
    end
  end
end
