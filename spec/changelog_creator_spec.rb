require "date"
require "changelog_creator"

describe ChangelogCreator do

  before do
    @creator = ChangelogCreator.new
    allow(Date).to receive(:today).and_return(Date.new(2022, 2, 1))
  end

  it "gets commits from a file" do
    filename = "./lib/example_commits.json"
    results = @creator.read_commits(filename)
    expect(results[0]["commit"]["author"]["name"]).to eq "Miranda Wilson"
  end

  it "checks commits file extension is valid" do
    filename = "./lib/changelog_creator.rb"
    expect { @creator.read_commits(filename) }.to raise_error(StandardError)
  end

  it "extracts the commit messages from saved JSON" do
    filename = "./lib/example_commits.json"
    json = @creator.read_commits(filename)
    messages = @creator.extract_messages(json)
    expect(messages.length).to eq 25
    expect(messages[0]).to eq "Attribute community contributions in changelog (#289)"
    expect(messages[1]).to eq "Remove logging of user supplied values (#286)"
  end

  it "parses commit messages" do
    message = "Remove logging of user supplied values (close #286)\n\n* Remove this text"
    expected = "Remove logging of user supplied values (#286)"
    expect(@creator.parse_message(message)).to eq expected
  end

  it "returns nil if the commit message doesn't have an issue number" do
    message = "Prepare for release"
    expect(@creator.parse_message(message)).to be nil
  end

  it "reads an existing changelog" do
    filename = "./lib/example_CHANGELOG"
    results = @creator.read_changelog(filename)
    expect(results[0]).to eq "Java 0.11.0 (2021-12-14)"
  end

  # would be better to extract this from the tags
  # use the GH API
  it "makes a version header" do
    version = "Java 0.12.0"
    expect(@creator.make_header(version)).to eq "Java 0.12.0 (2022-02-01)"
  end

  it "creates formatted commits for the current release" do
    commits = "./lib/example_commits.json"
    changelog = "./lib/truncated_CHANGELOG"
    expected = File.read "./lib/new_commits_only.md"
    expect(@creator.generate_log_for_new_commits(commits, changelog, "Java 0.99.0")).to eq expected
  end

  xit "appends commits to an existing changelog"
  xit "checks that all the release commits are present"
  xit "thanks external contributors"
  xit "can cope if there are brackets in the message"

end
