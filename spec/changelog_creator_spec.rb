require "date"
require "changelog_creator"

describe ChangelogCreator do
  before do
    @creator = ChangelogCreator.new
    allow(Date).to receive(:today).and_return(Date.new(2022, 2, 1))
  end

  it "gets commits from a file" do
    filename = "./lib/example_commits.json"
    results = @creator.read_commits_from_file(filename)
    expect(results[0]["commit"]["author"]["name"]).to eq "Miranda Wilson"
  end

  it "checks commits file extension is valid" do
    filename = "./lib/changelog_creator.rb"
    expect { @creator.read_commits(filename) }.to raise_error(StandardError)
  end

  it "gets commits from Github" do
    json = @creator.fetch_commits("snowplow", "snowplow-java-tracker", "master")
    expect(JSON.parse(json)[0]["commit"]["author"]["name"]).to eq "Miranda Wilson"
  end

  describe "extracting commit data" do
      it "parses one of my commits into a hash" do
      filename = "./lib/single_commit_me.json"
      parsed_json = @creator.read_commits_from_file(filename)

      results = @creator.process_single_commit(parsed_json)
      expect(results[:message]).to eq "Remove logging of user supplied values"
      expect(results[:issue]).to eq "286"
      expect(results[:author]).to eq "mscwilson"
      expect(results[:snowplower?]).to eq true
    end

    it "parses an external commit into a hash" do
      filename = "./lib/single_commit_ext.json"
      parsed_json = @creator.read_commits_from_file(filename)

      results = @creator.process_single_commit(parsed_json)
      expect(results[:message]).to eq "Allow Emitter to use a custom ExecutorService"
      expect(results[:issue]).to eq "278"
      expect(results[:author]).to eq "AcidFlow"
      expect(results[:snowplower?]).to eq false
    end

    it "returns nil for a commit without an issue number" do
      filename = "./lib/single_commit_not_for_changelog.json"
      parsed_json = @creator.read_commits_from_file(filename)

      results = @creator.process_single_commit(parsed_json)
      expect(results).to be nil
    end
  end



  # it "reads an existing changelog" do
  #   filename = "./lib/example_CHANGELOG"
  #   results = @creator.read_changelog(filename)
  #   expect(results[0]).to eq "Java 0.11.0 (2021-12-14)"
  # end

  # # would be better to extract this from the tags
  # # use the GH API
  # it "makes a version header" do
  #   version = "Java 0.12.0"
  #   expect(@creator.make_header(version)).to eq "Java 0.12.0 (2022-02-01)"
  # end

  # it "creates formatted commits for the current release" do
  #   commits = "./lib/example_commits.json"
  #   changelog = "./lib/truncated_CHANGELOG"
  #   expected = File.read "./lib/new_commits_only.md"
  #   expect(@creator.generate_log_for_new_commits(commits, changelog, "Java 0.99.0")).to eq expected
  # end

  # xit "creates a new changelog file"
  # xit "produce something when there's no changelog already"
  # xit "thanks external contributors"
  # xit "gets the commits using GH API"
  # xit "gets the version and date from tags using GH API"
  # xit "works if more than like 30 commits to add (GH API doesn't automatically show all the commits)"
end
