require "base64"

class Manager
  RELEASE_BRANCH_PATTERN = %r{release/(\d*\.*\d*\.*\d*\.*)}
  LOG_PATH = "./CHANGELOG"

  def initialize(access_token: ENV["ACCESS_TOKEN"],
                 client: Octokit::Client,
                 repo_name: ENV["GITHUB_REPOSITORY"],
                 api_connection: GithubApiConnection,
                 log_creator: ChangelogCreator)
    @octokit = api_connection.new(client: client.new(access_token:), repo_name:)
    @log_creator = log_creator.new(api_connection: @octokit)
  end

  def do_operation
    case ENV["INPUT_OPERATION"]
    when "prepare for release", "prepare"
      prepare_for_release
    when "github release notes", "github"
      github_release_notes
    else
      puts "Unexpected string input. '#{ENV['INPUT_OPERATION']}' is not a valid operation. Exiting action."
    end
  end

  def prepare_for_release
    puts "Doing 'prepare for release' operation."

    if pr_event? && pr_branches_release_and_main?
      version = version_number(branch_name: ENV["GITHUB_HEAD_REF"])

      commit_data = commits_data_for_log(version)
      if commit_data.nil?
        puts "No commits: nothing to do. Exiting action."
        puts
        puts Base64.strict_encode64("No release notes needed!")
        return
      end

      old_log = old_changelog_data
      new_log = new_changelog_text(commit_data, version, old_log)

      commit_files(version, new_log, old_log[:sha])

      puts old_log[:sha].nil? ? "CHANGELOG created." : "CHANGELOG updated."
      puts "Action completed."
    elsif pr_event?
      puts "Nothing to do. Exiting action."
    else
      puts "Operation 'prepare for release' was specified, but this isn't a PR event. Exiting action."
    end
    puts
    puts Base64.strict_encode64("No release notes needed!")
  end

  def github_release_notes
    "I'm creating GH release notes"
  end

  private #------------------------

  def commits_data_for_log(version)
    puts "Getting commit data for PR #{pr_number}..."
    commits = @octokit.commits_from_pr(number: pr_number)
    commits = @log_creator.relevant_commits(commits:, version:)

    if commits[0][:commit][:message].start_with? "Prepare for #{version} release"
      puts "Did this action already run? There's a 'Prepare for #{version} release' commit right there."
      return nil
    end

    if commits.empty?
      puts "No commits found."
      return nil
    end

    @log_creator.useful_commit_data(commits:)
  end

  def old_changelog_data(path: LOG_PATH)
    puts "Getting CHANGELOG file..."
    begin
      existing_changelog = @octokit.get_file(path:)
      puts "CHANGELOG found."
    rescue Octokit::NotFound
      puts "No existing CHANGELOG found, will make a new one."
      existing_changelog = { sha: nil, contents: "" }
    end
    existing_changelog
  end

  # this should be a ChangelogCreator method
  def new_changelog_text(commit_data, version, existing_changelog_data)
    new_log_section = @log_creator.simple_changelog_block(version:, commit_data:)
    "#{new_log_section}\n#{existing_changelog_data[:contents]}"
  end

  def commit_files(version, new_log, sha)
    commit_message = "Prepare for #{version} release"

    commit_result = @octokit.update_file(commit_message:,
                                         file_contents: new_log,
                                         file_path: LOG_PATH,
                                         sha: 
                                         )

    raise "Failed to commit new CHANGELOG." unless commit_result
  end

  def version_number(branch_name:)
    match = RELEASE_BRANCH_PATTERN.match(branch_name)
    return nil unless match

    version = match[1]
    version.count(".") == 1 ? "#{version}.0" : version
  end

  def pr_event?
    ENV["GITHUB_EVENT_NAME"] == "pull_request"
  end

  def pr_branches_release_and_main?
    puts "Checking it's a PR of the right sort..."
    unless %w[main master].include?(ENV["GITHUB_BASE_REF"])
      puts "This was not a PR opened against main/master branch."
      return false
    end

    unless ENV["GITHUB_HEAD_REF"][0..6] == "release"
      puts "This PR was not opened from a release branch."
      return false
    end
    puts "This PR was opened from a release branch into main/master. Continuing."
    true
  end

  def pr_number
    /\d+/.match(ENV["GITHUB_REF_NAME"])[0].to_i
  end
end
