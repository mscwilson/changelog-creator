require "date"
require "changelog_creator"

describe ChangelogCreator do

  before do
    @creator = ChangelogCreator.new
  end

  it "gets commits from a file" do
    filename = "./lib/example_commits.json"
    results = @creator.read_commits(filename)
    expect(results[0]["commit"]["author"]["name"]).to eq "Miranda Wilson"
  end

  it "checks file extension is valid" do
    filename = "./lib/changelog_creator.rb"
    expect { @creator.read_commits(filename) }.to raise_error(StandardError)
  end

  it "extracts the commit messages from saved JSON" do
    filename = "./lib/example_commits.json"
    json = @creator.read_commits(filename)
    messages = @creator.extract_messages(json)
    expect(messages.length).to eq 25
    expect(messages[0]).to eq "Attribute community contributions in changelog (#289)"
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


  it "makes a version header" do
    version = "Java 0.12.0"
    allow(Date).to receive(:today).and_return(Date.new(2022, 2, 1))
    expect(@creator.make_header(version)).to eq "Java 0.12.0 (2022-02-01)"
  end


  xit "creates formatted commits for the current release"
  xit "appends commits to an existing changelog"
  xit "checks that all the release commits are present"
  xit "thanks external contributors"
  xit "can cope if there are brackets in the message"

end
