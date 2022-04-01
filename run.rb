require "dotenv/load"
require "octokit"

require "./lib/github_api_connection"
require "./lib/changelog_creator"
require "./lib/manager"

LOG_PATH = "./CHANGELOG"

def run
  puts "Starting Changelog Creator."

  creator = ChangelogCreator.new
  manager = Manager.new

  # events = creator.octokit.repo_events
  # unless manager.pr_branches_release_and_main?
  #   puts "No action taken."
  #   return
  # end
  $stdout.write "Writing to STDOUT"
  puts "Puts'd this."

  `echo "hello world with backticks"`

  puts "::set-output name=fancylog::'hello world'"

  # commits = creator.octokit.commits_from_branch(branch_name: ENV["GITHUB_HEAD_REF"])
  # commit_data = creator.extract_relevant_commit_data(commits)

  # pr_number = events[0]["payload"]["number"]

  # commit_changelog_file(creator, branches[:head_ref], commit_data)

  # formatted_log = creator.fancy_changelog(commit_data:)
  # creator.octokit.comment_on_pr_or_issue(number: pr_number, text: formatted_log)
  # puts "Formatted changelog added as comment to PR ##{pr_number}"

  # puts "Action completed."
end

def commit_changelog_file(creator, branch_name, commits)
  puts "Getting CHANGELOG file."
  changelog_exists = true
  begin
    existing_changelog = creator.octokit.get_file(path: LOG_PATH)
  rescue Octokit::NotFound
    puts "No existing CHANGELOG found."
    existing_changelog = { sha: nil, contents: "" }
    changelog_exists = false
  end

  new_log_section = creator.simple_changelog_block(branch_name:, commit_data: commits)
  updated_log = "#{new_log_section}\n#{existing_changelog[:contents]}"

  if new_log_section.empty?
    puts "No version number found. No CHANGELOG file created."
  else
    commit_message = changelog_exists ? "Update CHANGELOG" : "Create CHANGELOG"
    creator.octokit.update_file(commit_message:,
                                file_contents: updated_log,
                                file_path: LOG_PATH,
                                sha: existing_changelog[:sha],
                                branch: branch_name)

    puts changelog_exists ? "CHANGELOG updated." : "CHANGELOG created."
  end
end

run
