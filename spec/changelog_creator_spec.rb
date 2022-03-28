require "date"
require "changelog_creator"

describe ChangelogCreator do
  before do
    @creator = ChangelogCreator.new
  end

  it "processes commits json into a list of new commit data" do
    commits_json_path = "./example_files_test/commits_two_good_two_admin.json"
    commits = File.read(commits_json_path)

    results = @creator.extract_relevant_commit_data(commits)
    expect(results.length).to eq 2

    expect(results[0][:message]).to eq("Choose HTTP response codes not to retry")
    expect(results[0][:issue]).to eq("316")
    expect(results[0][:author]).to eq("mscwilson")
    expect(results[0][:snowplower?]).to be true

    expect(results[1][:message]).to eq("Allow Emitter to use a custom ExecutorService")
    expect(results[1][:issue]).to eq("278")
    expect(results[1][:author]).to eq("AcidFlow")
    expect(results[1][:snowplower?]).to be false
  end

  it "gets the version number from the release branch name" do
    expect(@creator.extract_version_number("release/0.6.3")).to eq "0.6.3"
    expect(@creator.extract_version_number("release/5.0.3")).to eq "5.0.3"
    expect(@creator.extract_version_number("release/2.7")).to eq "2.7.0"
  end

  it "generates a simple CHANGELOG block" do
    commit = { message: "Publish Gradle module file with bintrayUpload",
      issue: "255",
      author: "me",
      snowplower?: true }
    another_commit = { message: "Update snyk integration to include project name in GitHub action",
      issue: "8",
      author: "SomeoneElse",
      snowplower?: false }
    processed_commits = [commit, another_commit]

    expected = "Version 0.2.0 (2022-02-01)\n-----------------------"\
      "\nPublish Gradle module file with bintrayUpload (#255)"\
      "\nUpdate snyk integration to include project name in GitHub action (#8) - thanks @SomeoneElse!\n"

    allow(@creator).to receive(:extract_version_number).and_return("0.2.0")
    allow(@creator).to receive(:extract_relevant_commit_data).and_return(processed_commits)
    allow(Date).to receive(:today).and_return(Date.new(2022, 2, 1))

    expect(@creator.simple_changelog_block("release/0.2.0", "pretend this is commits json")).to eq(expected)
  end

  # describe "gets the data" do
  #   it "gets commits from a file" do
  #     filename = "./lib/example_commits.json"
  #     results = @creator.read_commits_from_file(filename)
  #     expect(results[0]["commit"]["author"]["name"]).to eq "Miranda Wilson"
  #   end

  #   it "checks commits file extension is valid" do
  #     filename = "./lib/changelog_creator.rb"
  #     expect { @creator.read_commits(filename) }.to raise_error(StandardError)
  #   end

  #   it "gets commits from Github" do
  #     json = @creator.fetch_commits("snowplow", "snowplow-java-tracker", "master")
  #     expect(json[0]["commit"]["author"]["name"]).to eq "Miranda Wilson"
  #   end

  #   it "gets issue labels from Github" do
  #     json = @creator.fetch_issue_labels("snowplow", "snowplow-java-tracker", "286")
  #     expect(json[0]["name"]).to eq "type:enhancement"
  #   end

  #   it "reads a CHANGELOG" do
  #     filename = "./lib/example_CHANGELOG"
  #     results = @creator.read_changelog(filename)
  #     expect(results[0]).to eq "Java 0.11.0 (2021-12-14)"
  #   end
  # end

  # describe "extracts relevant commit data" do
  #   it "parses one of my commits into a hash" do
  #     filename = "./lib/single_commit_me.json"
  #     parsed_json = @creator.read_commits_from_file(filename)

  #     results = @creator.process_single_commit(parsed_json)
  #     expect(results[:message]).to eq "Remove logging of user supplied values"
  #     expect(results[:issue]).to eq "286"
  #     expect(results[:author]).to eq "mscwilson"
  #     expect(results[:snowplower?]).to eq true
  #   end

  #   it "parses an external commit into a hash" do
  #     filename = "./lib/single_commit_ext.json"
  #     parsed_json = @creator.read_commits_from_file(filename)

  #     results = @creator.process_single_commit(parsed_json)
  #     expect(results[:message]).to eq "Allow Emitter to use a custom ExecutorService"
  #     expect(results[:issue]).to eq "278"
  #     expect(results[:author]).to eq "AcidFlow"
  #     expect(results[:snowplower?]).to eq false
  #   end

  #   it "returns nil for a commit without an issue number" do
  #     filename = "./lib/single_commit_not_for_changelog.json"
  #     parsed_json = @creator.read_commits_from_file(filename)

  #     results = @creator.process_single_commit(parsed_json)
  #     expect(results).to be nil
  #   end
  # end

  # describe "extracts relevant issue label data" do
  #   it "parses a set of labels including 'type:enhancement'" do
  #     json = @creator.fetch_issue_labels("snowplow", "snowplow-java-tracker", "286")
  #     results = @creator.process_issue_labels(json)
  #     expect(results[:type]).to eq "type:enhancement"
  #     expect(results[:breaking_change?]).to be false
  #   end

  #   xit "breaking change"
  #   xit "the other types"
  # end

  # it "removes commits already in the CHANGELOG" do
  #   changelog = "./lib/truncated_CHANGELOG"
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
  # xit "works if someone put two type labels on there"
end
