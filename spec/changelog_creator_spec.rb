require "date"
require "changelog_creator"

describe ChangelogCreator do
  before do
    @fake_octocat = double
    allow(@fake_octocat).to receive(:new).and_return @fake_octocat
    @creator = ChangelogCreator.new(api_connection: @fake_octocat)
  end

  it "processes commits json into a list of new commit data" do
    commits_json_path = "./example_files_test/commits_two_good_two_admin.json"
    commits = File.read(commits_json_path)

    allow(@fake_octocat).to receive(:issue_labels)
      .and_return(["category:breaking_change", "type:enhancement"], ["type:defect"])

    results = @creator.relevant_commit_data(JSON.parse(commits))
    expect(results.length).to eq 2

    expect(results[0][:message]).to eq("Choose HTTP response codes not to retry")
    expect(results[0][:issue]).to eq("316")
    expect(results[0][:author]).to eq("mscwilson")
    expect(results[0][:snowplower]).to be true
    expect(results[0][:breaking_change]).to be true
    expect(results[0][:type]).to eq("feature")

    expect(results[1][:message]).to eq("Allow Emitter to use a custom ExecutorService")
    expect(results[1][:issue]).to eq("278")
    expect(results[1][:author]).to eq("AcidFlow")
    expect(results[1][:snowplower]).to be false
    expect(results[1][:type]).to eq "bug"
  end

  it "gets the version number from the release branch name" do
    expect(@creator.version_number("release/0.6.3")).to eq "0.6.3"
    expect(@creator.version_number("release/5.0.3")).to eq "5.0.3"
    expect(@creator.version_number("release/2.7")).to eq "2.7.0"
  end

  it "generates a simple CHANGELOG block" do
    commit = { message: "Publish Gradle module file with bintrayUpload",
               issue: "255",
               author: "me",
               snowplower: true }
    another_commit = { message: "Update snyk integration to include project name in GitHub action",
                       issue: "8",
                       author: "SomeoneElse",
                       snowplower: false }
    processed_commits = [commit, another_commit]

    expected = "Version 0.2.0 (2022-02-01)\n-----------------------"\
      "\nPublish Gradle module file with bintrayUpload (#255)"\
      "\nUpdate snyk integration to include project name in GitHub action (#8) - thanks @SomeoneElse!\n"

    allow(@creator).to receive(:version_number).and_return("0.2.0")
    allow(Date).to receive(:today).and_return(Date.new(2022, 2, 1))

    expect(@creator.simple_changelog_block(version: "0.2.0",
                                           commit_data: processed_commits)).to eq(expected)
  end

  it "generates a fancy changelog" do
    commit1 = { message: "Publish Gradle module file with bintrayUpload",
                issue: "255",
                author: "me",
                snowplower: true,
                breaking_change: false,
                type: "feature" }
    commit2 = { message: "Update snyk integration to include project name in GitHub action",
                issue: "8",
                author: "SomeoneElse",
                snowplower: false,
                breaking_change: true,
                type: "bug" }
    commit3 = { message: "Rename bufferSize to batchSize",
                issue: "306",
                author: "XenaPrincess",
                snowplower: true,
                breaking_change: true,
                type: "feature" }
    commit4 = { message: "Update all copyright notices",
                issue: "279",
                author: "XenaPrincess",
                snowplower: true,
                breaking_change: false,
                type: "admin" }
    commit5 = { message: "Allow Emitter to use a custom ExecutorService",
                issue: "278",
                author: "XenaPrincess",
                snowplower: true,
                breaking_change: true,
                type: nil }
    processed_commits = [commit1, commit2, commit3, commit4, commit5]

    expected = "**New features**\nPublish Gradle module file with bintrayUpload (#255)"\
      "\nRename bufferSize to batchSize (#306) **BREAKING CHANGE**"\
      "\n\n**Bug fixes**\nUpdate snyk integration to include project name in GitHub action (#8)"\
      " - thanks @SomeoneElse! **BREAKING CHANGE**\n\n"\
      "**Under the hood**\nUpdate all copyright notices (#279)\n"\
      "\n**Miscellaneous**\nAllow Emitter to use a custom ExecutorService (#278) **BREAKING CHANGE**\n"

    allow(@creator).to receive(:relevant_commit_data).and_return(processed_commits)

    expect(@creator.fancy_changelog(commit_data: processed_commits)).to eq(expected)
  end

  it "identifies a 'Prepare for x release' commit" do
    expect(@creator.prepare_for_release_commit?(message: "Prepare for 0.1.0 release")).to be true
    expect(@creator.prepare_for_release_commit?(message: "Prepare for v2.3 release")).to be true
    expect(@creator.prepare_for_release_commit?(message: "Prepare for release")).to be true
    expect(@creator.prepare_for_release_commit?(message: "Prepare to improve the API")).to be false
  end

  it "identifies a merge commit" do
    expect(@creator.merge_commit?(message: "Merge branch 'release/0.12.0'")).to be true
    expect(@creator.merge_commit?(message: "Merge pull request #67 from mscwilson/release/0.1.0")).to be true
    expect(@creator.merge_commit?(message: "Merge AbstractEmitter and BatchEmitter")).to be false
  end
end
