# frozen_string_literal: true

require "base64"

# Does the appropriate action depending on inputs, branch names etc.
class Manager
  RELEASE_VERSION_PATTERN = "\\d+\\.\\d+\\.\\d+(?:-\\w*\\.\\d+)?"
  RELEASE_BRANCH_PATTERN = %r{release/(#{RELEASE_VERSION_PATTERN})}
  LOG_PATH = "./CHANGELOG"
  DEFAULT_OUTPUT = "\n\n#{Base64.strict_encode64('No release notes needed!')}"

  attr_reader :octokit, :log_creator

  def initialize(access_token: ENV["ACCESS_TOKEN"],
                 client: Octokit::Client,
                 repo_name: ENV["GITHUB_REPOSITORY"],
                 api_connection: GithubApiConnection,
                 log_creator: ChangelogCreator)
    @octokit = api_connection.new(client: client.new(access_token:), repo_name:)
    @log_creator = log_creator.new(api_connection: @octokit)
    @prepare_commit_already_present = false
  end

  def do_operation
    case ENV["INPUT_OPERATION"]
    when "prepare for release", "prepare"
      prepare_for_release
    when "github release notes", "github"
      github_release_notes
    else
      puts "Unexpected string input. '#{ENV['INPUT_OPERATION']}' is not a valid operation. Exiting action."
      # Downstream actions to decode the output from this action won't fail
      # Because there actually is an encoded string output
      puts DEFAULT_OUTPUT
    end
  end

  def prepare_for_release
    puts "Doing 'prepare for release' operation."

    if pr_event? && pr_branches_release_and_main?
      update_and_commit_versions_and_changelog
      puts "Files updated, committed and pushed."
      puts "Action completed."
    elsif pr_event?
      puts "Nothing to do. Exiting action."
    else
      puts "Operation 'prepare for release' was specified, but this isn't a PR event. Exiting action."
    end
    puts DEFAULT_OUTPUT
  end

  def github_release_notes
    puts "Doing 'github release notes' operation."

    if tag_event?
      version = ENV["GITHUB_REF_NAME"]
      pull = @octokit.pr_from_title("Release/#{version}")
      if pull.nil?
        puts "Couldn't find a PR called 'Release/#{version}' or 'release/#{version}'. Unable to proceed."
        puts "\n#{Base64.strict_encode64('Unable to create release notes!')}"
        return
      end

      # Getting the name of the base branch - likely to be "main" or "master"
      branch_name = pull[:base][:ref]
      puts "Got description text from PR #{pull[:number]}."
      pr_text = pull[:body]

      commit_data = commits_data_for_release_notes(branch_name:, version:)
      if commit_data.nil? || commit_data.empty?
        puts "Nothing to do. Exiting action."
        puts DEFAULT_OUTPUT
        return
      end

      release_notes = github_release_notes_text(commit_data:, pr_text:)
      puts "Action completed."
      # The Action output is set based on the last line of the STDOUT
      # It has to be base64-encoded without newlines to move between jobs/steps in a GH workflow
      puts "\n#{Base64.strict_encode64(release_notes)}"

    else
      puts "Operation 'github release notes' was specified, but this isn't a tag event. Exiting action."
      puts DEFAULT_OUTPUT
    end
  end

  private #--------------------------------------------------

  def update_and_commit_versions_and_changelog
    version = version_number(branch_name: ENV["GITHUB_HEAD_REF"])

    # Steps for changing multiple files in one commit taken from blog post
    # https://juanitofatas.com/fragments/github_git_data_api
    current_branch = @octokit.ref(branch_name: ENV["GITHUB_HEAD_REF"])

    # If it wasn't a real branch - probably would only happen during testing
    if current_branch.nil?
      puts "Exiting action. #{DEFAULT_OUTPUT}"
      return
    end

    branch_sha = current_branch[:object][:sha]
    current_commit = @octokit.git_commit(sha: branch_sha)

    all_files_tree_data = updated_files_tree(branch_sha:, version:)

    if @prepare_commit_already_present || all_files_tree_data.nil?
      puts "Exiting action. #{DEFAULT_OUTPUT}"
      return
    end

    new_tree = @octokit.make_tree(tree_data: all_files_tree_data,
                                  base_tree_sha: current_commit[:tree][:sha])

    if new_tree.nil?
      puts "Unsuitable file paths. Unable to proceed. #{DEFAULT_OUTPUT}"
      return
    end

    commit_message = "Prepare for #{version} release"
    new_commit = @octokit.make_commit(commit_message:,
                                      tree_sha: new_tree[:sha],
                                      base_commit_sha: current_commit[:sha])

    # This pushes the changes
    @octokit.update_ref(branch_name: ENV["GITHUB_HEAD_REF"],
                        commit_sha: new_commit[:sha])
  end

  def updated_files_tree(branch_sha:, version:)
    puts "Updating CHANGELOG..."
    changelog_tree = changelog_tree(version:)
    return if @prepare_commit_already_present

    puts "Updating version strings..."
    version_files_tree = (version_files_tree(branch_sha:, version:) if ENV["INPUT_VERSION_SCRIPT_PATH"])

    if version_files_tree && changelog_tree
      puts "Ready to update version strings and CHANGELOG."
      version_files_tree + [changelog_tree]
    elsif version_files_tree
      puts "Ready to update version strings."
      version_files_tree
    elsif changelog_tree
      puts "Ready to update CHANGELOG."
      [changelog_tree]
    else
      puts "No files to update."
    end
  end

  def changelog_tree(version:)
    commit_data = commits_data_for_log(version:)
    return if @prepare_commit_already_present

    if commit_data.nil? || commit_data.empty?
      puts "No CHANGELOG-suitable commits found."
      return nil
    end

    new_log = @log_creator.new_changelog_text(commit_data:,
                                              version:,
                                              original_text: old_changelog_data[:contents])

    puts "Appended new commits to the existing CHANGELOG contents."
    {
      path: "CHANGELOG",
      mode: "100644",
      type: "blob",
      sha: @octokit.make_blob(text: new_log)
    }
  end

  def commits_data_for_log(version:)
    puts "Getting commit data for PR #{pr_number}..."
    commits = @octokit.commits_from_pr(number: pr_number)
    commits = @log_creator.relevant_commits(commits:, version:)

    if commits.nil? || commits.empty?
      puts "No commits found."
      return nil
    end

    if commits[-1][:commit][:message].start_with? "Prepare for #{version} release"
      puts "Did this action already run? There's a 'Prepare for #{version} release' commit right there."
      @prepare_commit_already_present = true
      return nil
    end

    @log_creator.useful_commit_data(commits:)
  end

  def commits_data_for_release_notes(branch_name:, version:)
    puts "Getting commit data for branch '#{branch_name}'..."

    commits = @octokit.commits_from_branch(branch_name:)
    commits = @log_creator.relevant_commits(commits:, version:)

    if commits.nil? || commits.empty?
      puts "No commits found."
      return nil
    end

    @log_creator.useful_commit_data(commits:)
  end

  def github_release_notes_text(commit_data:, pr_text:)
    "#{pr_text}\n\n#{@log_creator.fancy_changelog(commit_data:)}"
  end

  def old_changelog_data(path: LOG_PATH)
    puts "Getting CHANGELOG file..."
    begin
      existing_changelog = @octokit.file(path:)
      puts "CHANGELOG found."
    rescue Octokit::NotFound
      puts "No existing CHANGELOG found, will make a new one."
      existing_changelog = { sha: nil, contents: "" }
    end
    existing_changelog
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

  def pr_number(ref: ENV["GITHUB_REF_NAME"])
    /\d+/.match(ref)[0].to_i
  end

  def version_files_tree(branch_sha:, version:, path: ENV["INPUT_VERSION_SCRIPT_PATH"])
    puts "Getting the version strings location file..."
    # Get the version_locations.json file
    locations_file = @octokit.file(path:, ref: branch_sha)
    if locations_file.nil?
      puts "Are you sure that's the right path? Unable to find file."
      return
    end

    JSON.parse(locations_file[:contents]).each_with_object(files = []) { |(k, v), arr| arr << { path: k, strings: v } }

    files.each do |loc|
      process_file_version_locations(loc, branch_sha, version)
    end
    puts "Found all version string locations and updated text(s) to '#{version}'."

    files.map! do |f|
      {
        path: f[:path],
        mode: "100644",
        type: "blob",
        sha: @octokit.make_blob(text: f[:new_contents])
      }
    end
  end

  def process_file_version_locations(loc, branch_sha, version)
    # Allows for users not wrapping single strings as arrays
    loc[:strings] = [loc[:strings]] if loc[:strings].is_a? String

    file = @octokit.file(path: loc[:path], ref: branch_sha)
    loc[:current_contents] = file[:contents]
    loc[:sha] = file[:sha]

    # Remove "./" from the paths since it's not accepted by Github
    loc[:path] = loc[:path][2..] if loc[:path][0..1] == "./"

    loc[:strings].map! do |str|
      { original: str,
        as_pattern: Regexp.new(str.gsub(/(x\.x\.x)|(X\.X\.X)/, RELEASE_VERSION_PATTERN)),
        updated: str.gsub(/(x\.x\.x)|(X\.X\.X)/, version) }
    end

    loc[:strings].each_with_index do |str, i|
      loc[:new_contents] = if i.zero?
                             loc[:current_contents].gsub(str[:as_pattern], str[:updated])
                           else
                             loc[:new_contents].gsub(str[:as_pattern], str[:updated])
                           end
    end
  end
end
