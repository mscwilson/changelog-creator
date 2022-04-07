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
      "That's not a valid operation. Exiting action.\n").to_stdout
  end

  it "checks it's a PR event" do
    allow(ENV).to receive(:[]).with("GITHUB_EVENT_NAME").and_return("pull_request")
    expect(@manager.pr_event?).to be true

    allow(ENV).to receive(:[]).with("GITHUB_EVENT_NAME").and_return("push")
    expect(@manager.pr_event?).to be false
  end

  it "checks it's a PR from a release branch into main" do
    allow(ENV).to receive(:[]).with("GITHUB_BASE_REF").and_return("main")
    allow(ENV).to receive(:[]).with("GITHUB_HEAD_REF").and_return("release/0.1.0")

    expect(@manager.pr_branches_release_and_main?).to be true
  end

  it "returns false if it's not the right kind of PR" do
    allow(ENV).to receive(:[]).with("GITHUB_BASE_REF").and_return("release/1.3.2")
    allow(ENV).to receive(:[]).with("GITHUB_HEAD_REF").and_return("issue/123-feature")

    expect(@manager.pr_branches_release_and_main?).to be false
  end

  it "gets the PR number from ENV" do
    allow(ENV).to receive(:[]).with("GITHUB_REF_NAME").and_return("78/merge")
    expect(@manager.pr_number).to eq 78
  end
end
