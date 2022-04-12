# frozen_string_literal: true

require "date"
require "json"
require "manager"

describe Manager do
  before do
    @fake_octokit = double :octokit
    @fake_api_connection = double :api_connection
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
      expect(@manager).not_to receive :updated_files_tree

      @manager.do_operation
    end

    it "does nothing if not the right PR branches" do
      @fake_env["GITHUB_BASE_REF"] = "release/0.1.0"
      @fake_env["GITHUB_HEAD_REF"] = "issue/99-red_balloons"

      expect(@manager).not_to receive :updated_files_tree

      @manager.do_operation
    end

    it "doesn't do anything with versions if no locations file is provided" do
      @fake_env["INPUT_VERSION_SCRIPT_PATH"] = nil
      expect(@manager).not_to receive(:version_files_tree)
    end

    it "quits early if the last commit was already 'Prepare for {this} release'" do
      @fake_env["GITHUB_HEAD_REF"] = "release/0.2.0"

      commits_json_path = "./example_files_test/commits_first_is_prepare_for_x_release.json"
      commits = File.read(commits_json_path)
      allow(@fake_log_creator).to receive(:relevant_commits).and_return(JSON.parse(commits, symbolize_names: true))

      allow(@fake_octokit).to receive(:ref).and_return({ object: { sha: "abcde" } })
      allow(@fake_octokit).to receive(:git_commit).and_return({ tree: { sha: "abcde" }, sha: "123" })
      allow(@fake_octokit).to receive(:commits_from_pr)
      allow(@fake_octokit).to receive(:pull_request_commits).with("mscwilson/try-out-actions-here", 78)
      allow(@fake_octokit).to receive(:last_response)

      message = "Did this action already run? There's a 'Prepare for 0.2.0 release' commit right there."
      expect(@manager.octokit).not_to receive(:make_blob)
      expect { @manager.do_operation }.to output(/#{Regexp.quote(message)}/).to_stdout
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
  end
end
