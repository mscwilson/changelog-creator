# frozen_string_literal: true

require "date"
require "json"
require "manager"
require "changelog_creator"
require "github_api_connection"

describe Manager do
  before do
    @fake_octokit = double :client
    allow(@fake_octokit).to receive(:new).and_return @fake_octokit

    @manager = Manager.new(client: @fake_octokit, repo_name: "mscwilson/try-out-actions-here")

    @fake_env = {}
    allow(ENV).to receive(:[]) do |key|
      raise("#{key} not expected") unless @fake_env.key? key

      @fake_env[key]
    end
    @fake_env["COLUMNS"] = "why does rspec keep calling this?"
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
      @fake_env["GITHUB_HEAD_REF"] = "release/2.5.3"
      @fake_env["GITHUB_REF_NAME"] = "78/merge"
      @fake_env["INPUT_VERSION_SCRIPT_PATH"] = nil

      allow(@fake_octokit).to receive(:ref).and_return({ object: { sha: "abcde" } })
      allow(@fake_octokit).to receive(:git_commit).and_return({ tree: { sha: "abcde" }, sha: "123" })
      allow(@fake_octokit).to receive(:pull_request_commits).with("mscwilson/try-out-actions-here", 78)
      allow(@fake_octokit).to receive(:last_response)
    end

    it "does nothing if not a PR" do
      @fake_env["GITHUB_EVENT_NAME"] = "push"
      expect(@manager).not_to receive :updated_files_tree

      @manager.do_operation
    end

    it "does nothing if not the right PR branches" do
      @fake_env["GITHUB_BASE_REF"] = "release/0.1.0"
      @fake_env["GITHUB_HEAD_REF"] = "issue/99-red_balloons"

      expect(@manager).not_to receive :updated_files_tree

      @manager.do_operation
    end

    xit "creates and commits a new changelog" do
      @fake_env["GITHUB_HEAD_REF"] = "release/1.7"

      expect(Date).to receive(:today)
      expect(@manager).not_to receive(:version_files_tree)
      expect(@manager.log_creator).to receive(:new_changelog_text)

      expect(@manager.octokit).to receive(:make_blob)
      expect(@manager.octokit).to receive(:make_tree)
      expect(@manager.octokit).to receive(:make_commit)
      expect(@manager.octokit).to receive(:update_ref)

      expect { @manager.do_operation }.to output(/#{Regexp.quote("Files updated, committed and pushed.")}/).to_stdout
    end

    it "quits early if the last commit was already 'Prepare for {this} release'" do
      @fake_env["GITHUB_HEAD_REF"] = "release/0.2.0"

      commits_json_path = "./example_files_test/commits_first_is_prepare_for_x_release.json"
      commits = File.read(commits_json_path)

      message = "Did this action already run? There's a 'Prepare for 0.2.0 release' commit right there."

      allow(@manager.octokit).to receive(:commits_from_pr).and_return(JSON.parse(commits, symbolize_names: true))

      expect(@manager.octokit).not_to receive(:make_blob)
      expect { @manager.do_operation }.to output(/#{Regexp.quote(message)}/).to_stdout
    end

    it "doesn't do anything with versions if no locations file is provided" do
      @fake_env["INPUT_VERSION_SCRIPT_PATH"] = nil
      expect(@manager).not_to receive(:version_files_tree)
    end

    xit "tries to update version strings if locations file is provided" do
      @fake_env["INPUT_VERSION_SCRIPT_PATH"] = "version_locations.json"
      @fake_env["GITHUB_HEAD_REF"] = "release/2.5.3"


      # give something some files!

      expect(@manager).to receive(:version_files_tree)
      expect(@manager.octokit).to receive(:make_tree)
      # expect { @manager.do_operation }.to output(/#{Regexp.quote("Found all version string locations")}/).to_stdout
      @manager.do_operation

    end
  end

  describe "with 'github release notes'" do
    before do
      @fake_env["INPUT_OPERATION"] = "github release notes"
      @fake_env["GITHUB_REF_NAME"] = "3.2.1"
    end

    xit "outputs encoded release notes" do
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
