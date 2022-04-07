require "date"
require "manager"

describe Manager do
  before do
    @fake_octokit = double
    @fake_api_connection = double
    @fake_log_creator = double
    allow(@fake_octokit).to receive(:new)
    allow(@fake_api_connection).to receive(:new).and_return @fake_octokit
    allow(@fake_log_creator).to receive(:new).and_return @fake_log_creator

    @manager = Manager.new(client: @fake_octokit,
                           api_connection: @fake_api_connection,
                           log_creator: @fake_log_creator)
  end

  it "calls the appropriate method based on input operation" do
    allow(ENV).to receive(:[]).with("INPUT_OPERATION").and_return("prepare for release")
    expect(@manager).to receive :prepare_for_release
    @manager.do_operation

    allow(ENV).to receive(:[]).with("INPUT_OPERATION").and_return("github")
    expect(@manager).to receive :github_release_notes
    @manager.do_operation

    allow(ENV).to receive(:[]).with("INPUT_OPERATION").and_return("hello")
    expect { @manager.do_operation }.to output("Unexpected string input. "\
      "'hello' is not a valid operation. Exiting action.\n").to_stdout
  end

  it "does nothing if 'prepare for release' but not a PR" do
    allow(ENV).to receive(:[]).with("INPUT_OPERATION").and_return("prepare for release")
    allow(ENV).to receive(:[]).with("GITHUB_EVENT_NAME").and_return("push")
    expect(@manager).not_to receive :commits_data_for_log
    expect(@manager).not_to receive :commit_files

    @manager.do_operation
  end

  it "does nothing if 'prepare for release' but not the right PR branches" do
    allow(ENV).to receive(:[]).with("INPUT_OPERATION").and_return("prepare for release")
    allow(ENV).to receive(:[]).with("GITHUB_EVENT_NAME").and_return("pull_request")

    allow(ENV).to receive(:[]).with("GITHUB_BASE_REF").and_return("release/0.1.0")
    allow(ENV).to receive(:[]).with("GITHUB_HEAD_REF").and_return("issue/99-red_balloons")

    expect(@manager).not_to receive :commits_data_for_log
    expect(@manager).not_to receive :commit_files

    @manager.do_operation
  end

  it "creates a new changelog if 'prepare for release' with the right branches" do
    allow(ENV).to receive(:[]).with("INPUT_OPERATION").and_return("prepare for release")

    allow(ENV).to receive(:[]).with("GITHUB_EVENT_NAME").and_return("pull_request")
    allow(ENV).to receive(:[]).with("GITHUB_BASE_REF").and_return("main")
    allow(ENV).to receive(:[]).with("GITHUB_HEAD_REF").and_return("release/1.7")
    allow(ENV).to receive(:[]).with("GITHUB_REF_NAME").and_return("78/merge")

    allow(Date).to receive(:today).and_return(Date.new(2022, 5, 5))

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

    old_log = {sha: "12345", contents: "Version 0.2.0 (2022-02-01)\n-----------------------"\
      "\nPublish Gradle module file with bintrayUpload (#255)"\
      "\nUpdate snyk integration to include project name in GitHub action (#8) - thanks @SomeoneElse!\n"}

    new_log_section = "Version 1.7.0 (2022-05-05)\n-----------------------"\
      "\nChoose HTTP response codes not to retry (#316)"\
      "\nAllow Emitter to use a custom ExecutorService (#278) - thanks @AcidFlow!\n"

    new_log = "Version 1.7.0 (2022-05-05)\n-----------------------"\
      "\nChoose HTTP response codes not to retry (#316)"\
      "\nAllow Emitter to use a custom ExecutorService (#278) - thanks @AcidFlow!\n\n"\
      "Version 0.2.0 (2022-02-01)\n-----------------------"\
      "\nPublish Gradle module file with bintrayUpload (#255)"\
      "\nUpdate snyk integration to include project name in GitHub action (#8) - thanks @SomeoneElse!\n"

    allow(@fake_octokit).to receive(:commits_from_pr).with(number: 78)
    allow(@fake_log_creator).to receive(:relevant_commits).and_return([{commit: {message: "hello"}}])

    allow(@fake_log_creator).to receive(:useful_commit_data).and_return useful_commit_data
    allow(@fake_octokit).to receive(:get_file).and_return old_log

    allow(@fake_log_creator).to receive(:simple_changelog_block).and_return new_log_section

    expect(@manager).to receive(:commit_files).with("1.7.0", new_log, "12345")
    @manager.do_operation
  end

  xit "quits early if 'prepare for release' but the last commit was already 'Prepare for release'"

  # xit "gets the version number from the release branch name" do
  #   expect(@manager.version_number(branch_name: "release/0.6.3")).to eq "0.6.3"
  #   expect(@manager.version_number(branch_name: "release/5.0.3")).to eq "5.0.3"
  #   expect(@manager.version_number(branch_name: "release/2.7")).to eq "2.7.0"
  # end

  
end
