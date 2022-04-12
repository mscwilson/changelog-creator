# frozen_string_literal: true

require "date"
require "changelog_creator"

describe ChangelogCreator do
  before do
    @fake_octocat = double
    allow(@fake_octocat).to receive(:new).and_return @fake_octocat
    @creator = ChangelogCreator.new(api_connection: @fake_octocat)
  end

  it "gets the relevant commits, and bits of commits, out of the raw response" do
    commits_json_path = "./example_files_test/commits_two_good_two_admin.json"
    commits = File.read(commits_json_path)

    allow(@fake_octocat).to receive(:issue_labels)
      .and_return(["category:breaking_change", "type:enhancement"], ["type:defect"])
    # allow(@fake_octocat).to receive(:snowplower?).and_return(true, false)

    commit1 = { message: "Choose HTTP response codes not to retry",
                issue: "316",
                author: "mscwilson",
                # snowplower: true,
                breaking_change: true,
                type: "feature" }
    commit2 = { message: "Allow Emitter to use a custom ExecutorService",
                issue: "278",
                author: "AcidFlow",
                # snowplower: false,
                breaking_change: false,
                type: "bug" }

    results = @creator.useful_commit_data(commits: JSON.parse(commits, symbolize_names: true))
    expect(results.length).to eq 2
    expect(results[0]).to eq commit1
    expect(results[1]).to eq commit2
  end

  it "doesn't stop at the Prepare to release commit for this release" do
    commits_json_path = "./example_files_test/commits_master_tJ.json"
    commits = File.read(commits_json_path)
    allow(@fake_octocat).to receive(:issue_labels).and_return []

    results = @creator.relevant_commits(commits: JSON.parse(commits, symbolize_names: true), version: "0.12.0")

    expect(results.length).to eq 16
    expect(results[0][:commit][:message]).to eq("Merge branch 'release/0.12.0'")
    expect(results[1][:commit][:message]).to eq("Prepare for 0.12.0 release\n\n* Remove unused imports in "\
                                                "simple-console\r\n\r\n* Update version number\r\n\r\n* "\
                                                "Note which Event.Builder methods are required\r\n\r\n* "\
                                                "Add link to Javadocs to README\r\n\r\n* Update CHANGELOG")
    expect(results[-1][:commit][:message]).to eq("Attribute community contributions in changelog (close #289)")
  end

  it "generates a new CHANGELOG" do
    commit = { message: "Publish Gradle module file with bintrayUpload",
               issue: "255",
               author: "me" }
    another_commit = { message: "Update snyk integration to include project name in GitHub action",
                       issue: "8",
                       author: "SomeoneElse" }
    processed_commits = [commit, another_commit]
    old_log = "Version 0.1.0 (2015-11-13)\n-----------------------\nInvented a thing (#2)\n"

    expected = "Version 0.2.0 (2022-02-01)\n-----------------------"\
               "\nPublish Gradle module file with bintrayUpload (#255)"\
               "\nUpdate snyk integration to include project name in GitHub action (#8)\n\n"\
               "Version 0.1.0 (2015-11-13)\n-----------------------"\
               "\nInvented a thing (#2)\n"

    allow(Date).to receive(:today).and_return(Date.new(2022, 2, 1))

    expect(@creator.new_changelog_text(version: "0.2.0",
                                       commit_data: processed_commits,
                                       original_text: old_log)).to eq(expected)
  end

  it "generates a fancy changelog" do
    commit1 = { message: "Publish Gradle module file with bintrayUpload",
                issue: "255",
                author: "me",
                # snowplower: true,
                breaking_change: false,
                type: "feature" }
    commit2 = { message: "Update snyk integration to include project name in GitHub action",
                issue: "8",
                author: "SomeoneElse",
                # snowplower: false,
                breaking_change: true,
                type: "bug" }
    commit3 = { message: "Rename bufferSize to batchSize",
                issue: "306",
                author: "XenaPrincess",
                # snowplower: true,
                breaking_change: true,
                type: "feature" }
    commit4 = { message: "Update all copyright notices",
                issue: "279",
                author: "XenaPrincess",
                # snowplower: true,
                breaking_change: false,
                type: "admin" }
    commit5 = { message: "Allow Emitter to use a custom ExecutorService",
                issue: "278",
                author: "XenaPrincess",
                # snowplower: true,
                breaking_change: true,
                type: nil }
    processed_commits = [commit1, commit2, commit3, commit4, commit5]

    expected = "**New features**\nPublish Gradle module file with bintrayUpload (#255)"\
               "\nRename bufferSize to batchSize (#306) **BREAKING CHANGE**"\
               "\n\n**Bug fixes**\nUpdate snyk integration to include project name in GitHub action (#8)"\
               " **BREAKING CHANGE**\n\n"\
               "**Under the hood**\nUpdate all copyright notices (#279)\n"\
               "\n**Changes**\nAllow Emitter to use a custom ExecutorService (#278) **BREAKING CHANGE**\n"

    allow(@creator).to receive(:useful_commit_data).and_return(processed_commits)

    expect(@creator.fancy_changelog(commit_data: processed_commits)).to eq(expected)
  end
end
