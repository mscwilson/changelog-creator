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

  pr_action = manager.pr_branches_release_and_main?

  if pr_action
    # Commit a new CHANGELOG file into the release branch
    update_changelog(creator)

  else
    # Output release notes to use as part of a GH deploy workflow
    # Working on the assumption that the release PR was the most recently made (highest number)
    # Not necessarily true
    pull = creator.octokit.repo_pull_requests[0]
    branch_name = pull["base"]["ref"]
    pull_description = pull["body"]

    commits = creator.octokit.commits_from_branch(branch_name:)
    # Temporary hack to allow for the existence of the "Prepare for release" and merge commit
    # Just ignoring the most recent two commits
    commit_data = creator.relevant_commit_data(commits[2..])
    formatted_log = creator.fancy_changelog(commit_data:)

    release_notes = "#{pull_description}\n\n#{formatted_log}"

    puts "Action completed."
    puts
    puts Base64.strict_encode64(release_notes)
  end
end

def update_changelog(creator)
  commits = creator.octokit.commits_from_branch(branch_name: ENV["GITHUB_HEAD_REF"])
  version = creator.version_number(branch_name: ENV["GITHUB_HEAD_REF"])
  commits = creator.relevant_commits(commits:, version:)

  if commits[0][:commit][:message].start_with? "Prepare for #{version} release"
    puts "Did this action already run? There's a 'Prepare for release' commit right there."
    puts "Exiting action."
    return
  end

  if commits.empty?
    puts "No commits found. Exiting action."
    return
  end

  commit_data = creator.relevant_commit_data(commits:)
  commit_changelog_file(creator, ENV["GITHUB_HEAD_REF"], commit_data, version)
  puts "Action completed."
  puts
  puts Base64.strict_encode64("No release notes needed!")
  nil
end

def commit_changelog_file(creator, branch_name, commits, version)
  puts "Getting CHANGELOG file..."
  changelog_exists = true
  begin
    existing_changelog = creator.octokit.get_file(path: LOG_PATH)
    puts "CHANGELOG found."
  rescue Octokit::NotFound
    puts "No existing CHANGELOG found."
    existing_changelog = { sha: nil, contents: "" }
    changelog_exists = false
  end

  new_log_section = creator.simple_changelog_block(version:, commit_data: commits)
  updated_log = "#{new_log_section}\n#{existing_changelog[:contents]}"
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

run
