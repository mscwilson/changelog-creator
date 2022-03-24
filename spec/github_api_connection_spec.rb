require "github_api_connection"

describe GithubApiConnection do
  before do
    @connection = GithubApiConnection.new
  end

  it "returns the head and base for a new PR" do
    events_json_path = "./example_files_test/events_pullrequestevent_opened.json"
    events = File.read(events_json_path)

    fake_client = double :client
    allow(fake_client).to receive(:repository_events).and_return(events)

    expect(@connection.pr_opened?(fake_client)).to eq ({ head_ref: "issue/19-hello", base_ref: "main" })
  end

  it "returns nil if the last event wasn't a new PR" do
    events_json_path = "./example_files_test/events_pullrequestevent_closed.json"
    events = File.read(events_json_path)

    fake_client = double :client
    allow(fake_client).to receive(:repository_events).and_return(events)

    expect(@connection.pr_opened?(fake_client)).to be_nil
  end

end
