require "./lib/github_api_connection"
require "./lib/changelog_creator"
require "octokit"


puts "Starting Changelog Creator"

client = Octokit::Client.new(access_token: "secret")

connection = GithubApiConnection.new(client: client, repo_name: "mscwilson/changelog-creator")
creator = ChangelogCreator.new


# connection.update_file(commit_message: "Testing update_contents",
#    file_contents: "adding stuff to a file on a branch",
#     file_path: "./new_file",
#      branch: "this-is-a-branch")

connection.pr_opened_to_main?
