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

  if manager.pr_branches_release_and_main?
    commits = creator.octokit.commits_from_branch(branch_name: ENV["GITHUB_HEAD_REF"])
    commit_data = creator.relevant_commit_data(commits)
    commit_changelog_file(creator, ENV["GITHUB_HEAD_REF"], commit_data)
    puts "Action completed."
    return
  end

  # events = creator.octokit.repo_events
  # pr_number = events[0]["payload"]["number"]

  # formatted_log = creator.fancy_changelog(commit_data:)
  # creator.octokit.comment_on_pr_or_issue(number: pr_number, text: formatted_log)
  # puts "Formatted changelog added as comment to PR ##{pr_number}"
  # puts "Action completed."
  puts "Finished."
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

  version = creator.version_number(branch_name)

  new_log_section = creator.simple_changelog_block(version:, commit_data: commits)
  updated_log = "#{new_log_section}\n#{existing_changelog[:contents]}"


  if new_log_section.empty?
    puts "No version number found. No CHANGELOG file created."
  else
    commit_message = "Prepare for #{version} release"
    commit_result = creator.octokit.update_file(commit_message:,
                                                file_contents: updated_log,
                                                file_path: LOG_PATH,
                                                sha: existing_changelog[:sha],
                                                branch: branch_name)

    unless commit_result
      puts "Failed to commit new CHANGELOG."
      return
    end

    puts changelog_exists ? "CHANGELOG updated." : "CHANGELOG created."
  end
end

run
