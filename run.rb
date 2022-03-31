require "./lib/github_api_connection"
require "./lib/changelog_creator"
require "octokit"

LOG_PATH = "./CHANGELOG"

def run
  puts "Starting Changelog Creator"

  creator = ChangelogCreator.new(access_token: "secret",
                                 repo_name: "mscwilson/try-out-actions-here")

  # events = connection.repo_events
  # unless connection.pr_opened_to_main?(events)
  #   puts "No action taken."
  #   return
  # end

  # commit_new_changelog(connection, creator)

  comment = creator.octokit.comment_on_pr_or_issue(number: 2)
  p comment
end

def commit_new_changelog(connection, creator)
  branches = connection.pr_branches(events[0])
  commits = connection.commits_from_branch(branch_name: branches[:head_ref])

  changelog_exists = true
  begin
    existing_changelog = connection.get_file(path: LOG_PATH)
  rescue Octokit::NotFound
    puts "No existing CHANGELOG found."
    existing_changelog = { sha: nil, contents: "" }
    changelog_exists = false
  end

  new_log_section = creator.simple_changelog_block(branch_name: branches[:head_ref], commits:)
  updated_log = "#{new_log_section}\n#{existing_changelog[:contents]}"

  commit_message = changelog_exists ? "Update CHANGELOG" : "Create CHANGELOG"
  connection.update_file(commit_message:,
                         file_contents: updated_log,
                         file_path: LOG_PATH,
                         sha: existing_changelog[:sha],
                         branch: branches[:head_ref])

  puts changelog_exists ? "CHANGELOG updated." : "CHANGELOG created."
end

run
