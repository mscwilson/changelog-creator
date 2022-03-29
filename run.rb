require "./lib/github_api_connection"
require "./lib/changelog_creator"
require "octokit"

LOG_PATH = "./CHANGELOG"

def run
  puts "Starting Changelog Creator"

  client = Octokit::Client.new(access_token: "secret")

  connection = GithubApiConnection.new(client: client, repo_name: "mscwilson/try-out-actions-here")
  creator = ChangelogCreator.new

  events = connection.repo_events
  unless connection.pr_opened_to_main?(events)
    puts "No action taken."
    return
  end

  branches = connection.pr_branches(events[0])
  commits = connection.commits_from_branch(branch_name: branches[:head_ref])
  existing_changelog = connection.get_file(path: LOG_PATH)
  new_log_section = creator.simple_changelog_block(branch_name: branches[:head_ref], commits: commits)
  updated_log = "#{new_log_section}\n#{existing_changelog[:contents]}"

  connection.update_file(commit_message: "Update CHANGELOG",
                         file_contents: updated_log,
                         file_path: LOG_PATH,
                         sha: existing_changelog[:sha],
                         branch: branches[:head_ref])
end

run
