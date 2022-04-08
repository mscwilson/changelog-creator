require "base64"

# Does the appropriate action depending on inputs, branch names etc
class Manager
  RELEASE_VERSION_PATTERN = "\\d+\\.\\d+\\.\\d+(?:-\\w*\\.\\d+)?"
  RELEASE_BRANCH_PATTERN = %r{release/(#{RELEASE_VERSION_PATTERN})}
  LOG_PATH = "./CHANGELOG"

  attr_reader :octokit

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

  def find_version_strings(path: ENV["INPUT_VERSION_SCRIPT_PATH"])
    version = "6.6.6"

    current_branch = @octokit.ref(branch_name: ENV["GITHUB_HEAD_REF"])
    branch_sha = current_branch.object.sha

    # Get the version_locations.json file
    file = @octokit.get_file(path:, ref: branch_sha)

    files_to_update = []
    JSON.parse(file[:contents]).each { |k, v| files_to_update << { path: k, strings: v } }

    files_to_update.each do |loc|
      process_file_version_locations(loc, branch_sha, version)
    end

    files_to_update.map! do |file|
      {
        path: file[:path],
        mode: "100644",
        type: "blob",
        sha: @octokit.make_blob(text: file[:new_contents])
      }
    end
    p files_to_update
  end

  def prepare_for_release
    puts "Doing 'prepare for release' operation."

    if pr_event? && pr_branches_release_and_main?
      version = version_number(branch_name: ENV["GITHUB_HEAD_REF"])

      commit_data = commits_data_for_log(version)
      if commit_data.nil? || commit_data.empty?
        puts "Nothing to do. Exiting action."
        puts
        puts Base64.strict_encode64("No release notes needed!")
        return
      end

      old_log = old_changelog_data
      new_log = @log_creator.new_changelog_text(commit_data:, version:, original_text: old_log[:contents])

      puts "ready to commit"
      # commit_files(version, new_log, old_log[:sha])

      puts old_log[:sha].nil? ? "CHANGELOG created." : "CHANGELOG updated."
      puts "Action completed."
    elsif pr_event?
      puts "Nothing to do. Exiting action."
    else
      puts "Operation 'prepare for release' was specified, but this isn't a PR event. Exiting action."
    end
    puts
    # These print statements are included mainly for testing
    # Downstream actions to decode the output from this action won't fail
    # Because there actually is an encoded string output
    puts Base64.strict_encode64("No release notes needed!")
  end

  def github_release_notes
    puts "Doing 'github release notes' operation."

    if tag_event?
      version = ENV["GITHUB_REF_NAME"]
      pull = @octokit.pr_from_title("Release/#{version}")

      # Getting the name of the base branch - likely to be "main" or "master"
      branch_name = pull[:base][:ref]
      puts "Got description text from PR #{pull[:number]}."
      pr_text = pull[:body]

      commit_data = commits_data_for_release_notes(branch_name:, version:)
      if commit_data.nil? || commit_data.empty?
        puts "Nothing to do. Exiting action."
        puts
        puts Base64.strict_encode64("No release notes needed!")
        return
      end

      release_notes = github_release_notes_text(commit_data:, pr_text:)
      puts "Action completed."
      puts
      # The Action output is set based on the last line of the STDOUT
      # It has to be base64-encoded without newlines to move between jobs/steps in a GH workflow
      puts Base64.strict_encode64(release_notes)

    else
      puts "Operation 'github release notes' was specified, but this isn't a tag event. Exiting action."
      puts
      puts Base64.strict_encode64("No release notes needed!")
    end
  end

  private #--------------------------------------------------

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

  def commits_data_for_release_notes(branch_name:, version:)
    puts "Getting commit data for branch '#{branch_name}'..."

    commits = @octokit.commits_from_branch(branch_name:)
    commits = @log_creator.relevant_commits(commits:, version:)
    @log_creator.useful_commit_data(commits:)
  end

  def github_release_notes_text(commit_data:, pr_text:)
    "#{pr_text}\n\n#{@log_creator.fancy_changelog(commit_data:)}"
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

  def commit_files(version, new_log, sha)
    commit_message = "Prepare for #{version} release"

    commit_result = @octokit.update_file(commit_message:,
                                         file_contents: new_log,
                                         file_path: LOG_PATH,
                                         sha:)

    raise "Failed to commit new CHANGELOG." unless commit_result
  end

  def version_number(branch_name:)
    match = RELEASE_BRANCH_PATTERN.match(branch_name)
    return nil unless match

    version = match[1]
    version.count(".") == 1 ? "#{version}.0" : version
  end

  def tag_event?
    ENV["GITHUB_REF_TYPE"] == "tag"
  end

  def pr_event?
    ENV["GITHUB_EVENT_NAME"] == "pull_request"
  end

  def pr_branches_release_and_main?
    puts "Checking it's a PR of the right branches..."
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

  def process_file_version_locations(loc, branch_sha, version)
    # Allows for users not wrapping single strings as arrays
    loc[:strings] = [loc[:strings]] if loc[:strings].is_a? String

    file = @octokit.get_file(path: loc[:path], ref: branch_sha)
    loc[:current_contents] = file[:contents]
    loc[:sha] = file[:sha]
    # loc[:current_tree] = @octokit.git_commit(sha: file[:sha])[:tree]

    loc[:strings].map! do |str|
      { original: str,
        as_pattern: Regexp.new(str.sub(/(x\.x\.x)|(X\.X\.X)/, RELEASE_VERSION_PATTERN)),
        updated: str.sub(/(x\.x\.x)|(X\.X\.X)/, version) }
    end

    loc[:strings].each_with_index do |str, i|
      loc[:new_contents] = if i.zero?
                             loc[:current_contents].sub(str[:as_pattern], str[:updated])
                           else
                             loc[:new_contents].sub(str[:as_pattern], str[:updated])
                           end
    end
  end
end
