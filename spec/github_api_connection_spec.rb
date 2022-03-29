require "github_api_connection"

describe GithubApiConnection do
  before do
    @fake_client = double :client
    @connection = GithubApiConnection.new(client: @fake_client)
  end

  it "checks if a new PR was opened into main/master" do
    events_json_path = "./example_files_test/events_pullrequestevent_opened.json"
    file = File.read(events_json_path)
    expect(@connection.pr_opened_to_main?(JSON.parse(file))).to be true
  end

  it "returns false if the PR wasn't to main" do
    events_json_path = "./example_files_test/events_pullrequestevent_opened_not_main.json"
    file = File.read(events_json_path)
    expect(@connection.pr_opened_to_main?(JSON.parse(file))).to be false
  end

  it "returns the head and base for a new PR" do
    events_json_path = "./example_files_test/events_pullrequestevent_opened.json"
    file = File.read(events_json_path)
    expect(@connection.pr_branches(JSON.parse(file)[0])).to eq({ head_ref: "release/1.2.3", base_ref: "main" })
  end

  it "gets existing CHANGELOG" do
    log_file_path = "./example_files_test/changelog_file_tJ.json"
    log_string_path = "./example_files_test/changelog_tJ.txt"
    log_file = File.read(log_file_path)
    log_string = File.read(log_string_path)
    result = { sha: "e55776f260d163ad073c3304c1c5b690328d93d1",
               contents: log_string }

    allow(@fake_client).to receive(:contents).and_return(JSON.parse(log_file, symbolize_names: true))
    expect(@connection.get_file(path: "CHANGELOG")).to eq(result)
  end
end
