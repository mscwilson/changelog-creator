require "date"
require "changelog_creator"

describe ChangelogCreator do
  before do
    @creator = ChangelogCreator.new
  end

  it "processes commits json into a list of new commit data" do
    commits_json_path = "./example_files_test/commits_two_good_two_admin.json"
    commits = File.read(commits_json_path)

    results = @creator.extract_relevant_commit_data(JSON.parse(commits))
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

    expect(@creator.simple_changelog_block(branch_name: "release/0.2.0",
                                           commits: "pretend this is commits")).to eq(expected)
  end
end
