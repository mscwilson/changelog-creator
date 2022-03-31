require 'dotenv/load'
require "octokit"

require "./lib/github_api_connection"
require "./lib/changelog_creator"

LOG_PATH = "./CHANGELOG"

def run
  puts "Starting Changelog Creator."

  creator = ChangelogCreator.new

  events = connection.repo_events
  unless connection.pr_opened_to_main?(events)
    puts "No action taken."
    return
  end

  branches = creator.octokit.pr_branches(events[0])
  commits = creator.octokit.commits_from_branch(branch_name: branches[:head_ref])
  commit_data = creator.extract_relevant_commit_data(commits)

  pr_number = events[0]["payload"]["number"]

  commit_changelog_file(creator, branches[:head_ref], commit_data)

  formatted_log = creator.fancy_changelog(commit_data:)
  creator.octokit.comment_on_pr_or_issue(number: pr_number, text: formatted_log)
  puts "Formatted changelog added as comment to PR ##{pr_number}"

  puts "Action completed."
end

def commit_changelog_file(creator, branch_name, commits)
  changelog_exists = true
  begin
    existing_changelog = connection.get_file(path: LOG_PATH)
  rescue Octokit::NotFound
    puts "No existing CHANGELOG found."
    existing_changelog = { sha: nil, contents: "" }
    changelog_exists = false
  end

  new_log_section = creator.simple_changelog_block(branch_name:, commits:)
  updated_log = "#{new_log_section}\n#{existing_changelog[:contents]}"

  commit_message = changelog_exists ? "Update CHANGELOG" : "Create CHANGELOG"
  connection.update_file(commit_message:,
                         file_contents: updated_log,
                         file_path: LOG_PATH,
                         sha: existing_changelog[:sha],
                         branch: branches[:head_ref])

  puts changelog_exists ? "CHANGELOG updated." : "CHANGELOG created."
end

# run
