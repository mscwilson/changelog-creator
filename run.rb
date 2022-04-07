require "dotenv/load"
require "octokit"

require "./lib/github_api_connection"
require "./lib/changelog_creator"
require "./lib/manager"

LOG_PATH = "./CHANGELOG"

def run
  puts "Starting Release Helper."
  puts "Specified operation was: '#{ENV['INPUT_OPERATION']}'."

  # creator = ChangelogCreator.new
  manager = Manager.new

  manager.do_operation
end

def create_release_notes(creator)
  version = ENV["GITHUB_REF_NAME"]

  pull = creator.octokit.pr_from_title("Release/#{version}")
  pull_description = pull["body"]

  # Getting the name of the base branch - likely to be "main" or "master"
  branch_name = pull["base"]["ref"]

  commits = creator.octokit.commits_from_branch(branch_name:)
  commits = creator.relevant_commits(commits:, version:)
  commit_data = creator.useful_commit_data(commits:)

  formatted_log = creator.fancy_changelog(commit_data:)

  release_notes = "#{pull_description}\n\n#{formatted_log}"

  puts "Action completed."
  puts
  puts Base64.strict_encode64(release_notes)
end

run
