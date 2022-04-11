# frozen_string_literal: true

require "github_api_connection"

describe GithubApiConnection do
  before do
    @fake_client = double :client
    @connection = GithubApiConnection.new(client: @fake_client)
  end

  it "gets existing CHANGELOG" do
    # the file contents are base-64 encoded
    log_file_path = "./example_files_test/changelog_file_tJ.json"
    log_string_path = "./example_files_test/changelog_tJ.txt"
    log_file = File.read(log_file_path)
    log_string = File.read(log_string_path)
    result = { sha: "e55776f260d163ad073c3304c1c5b690328d93d1",
               contents: log_string }

    allow(@fake_client).to receive(:contents).and_return(JSON.parse(log_file, symbolize_names: true))
    expect(@connection.get_file(path: "CHANGELOG")).to eq(result)
  end

  it "gets a list of the labels from an issue" do
    file_path = "./example_files_test/issue_multiple_labels.json"
    file = File.read(file_path)
    allow(@fake_client).to receive(:labels_for_issue).and_return(JSON.parse(file, symbolize_names: true))

    results = ["enhancement", "help wanted", "good first issue"]
    expect(@connection.issue_labels(issue: "27")).to eq(results)
  end

  it "gets a PR based on its name" do
    file_path = "./example_files_test/pulls.json"
    file = File.read(file_path)

    result_path = "./example_files_test/pulls_only_release.json"
    result = File.read(result_path)

    allow(@connection).to receive(:repo_pull_requests).and_return(JSON.parse(file, symbolize_names: true))

    expect(@connection.pr_from_title("Release/0.1.0")).to eq JSON.parse(result, symbolize_names: true)
  end
end
