require "github_api_connection"

describe GithubApiConnection do
  before do
    @fake_client = double :client
    @connection = GithubApiConnection.new(client: @fake_client)
  end

  it "returns the head and base for a new PR" do
    events_json_path = "./example_files_test/events_pullrequestevent_opened.json"
    allow(@fake_client).to receive(:repository_events).and_return(File.read(events_json_path))

    expect(@connection.pr_opened?).to eq({ head_ref: "issue/19-hello", base_ref: "main" })
  end

  it "returns nil if the last event wasn't a new PR" do
    events_json_path = "./example_files_test/events_pullrequestevent_closed.json"
    allow(@fake_client).to receive(:repository_events).and_return(File.read(events_json_path))

    expect(@connection.pr_opened?).to be_nil
  end

  # pointless test as is
  it "gets commits for a given branch" do
    commits_json_path = "./example_files_test/commits_master_tJ.json"
    commits = File.read(commits_json_path)
    allow(@fake_client).to receive(:commits).and_return(commits)

    expect(@connection.commits_from_branch("master")).to eq(commits)
  end

  it "gets existing CHANGELOG" do
    log_file_path = "./example_files_test/changelog_file_tJ.json"
    log_string_path = "./example_files_test/changelog_tJ.txt"
    log_file = File.read(log_file_path)

    allow(@fake_client).to receive(:contents).and_return(JSON.parse(log_file, symbolize_names: true))
    expect(@connection.get_file(path: "CHANGELOG")).to eq(File.read(log_string_path))
  end

  xit "returns nil if branch doesn't exist or there are no commits there"
end
