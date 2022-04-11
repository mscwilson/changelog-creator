# frozen_string_literal: true

require "octokit"
require "json"
require "base64"

# Wrapper for Octokit::Client.
class GithubApiConnection
  attr_reader :client

  def initialize(client: Octokit::Client.new(access_token: ENV["ACCESS_TOKEN"]), repo_name: ENV["GITHUB_REPOSITORY"])
    @client = client
    @repo_name = repo_name
  end

  def repo_events
    # NB there can be a delay for a new PR to show up at the "events" endpoint
    # (it will appear in the "pulls" endpoint instantly)
    @client.repository_events(@repo_name)
  end

  def repo_pull_requests
    @client.pull_requests(@repo_name, state: "all")
  end

  def pr_from_title(title)
    pulls = repo_pull_requests
    pulls.select! { |pull| pull[:title].downcase == title.downcase }[0]
  end

  def snowplower?(username)
    @client.organization_member?("snowplow", username)
  end

  def commits_from_branch(branch_name:)
    begin
      commits = @client.commits(@repo_name, sha: branch_name)
    rescue Octokit::NotFound
      puts "Unable to find branch '#{branch_name}', so couldn't get commits."
      return nil
    end
    second_page(commits)
  end

  def commits_from_pr(number:)
    number = number.to_i if number.is_a? String
    begin
      commits = @client.pull_request_commits(@repo_name, number)
    rescue Octokit::NotFound
      puts "Unable to find PR #{number}, so couldn't get commits."
      return nil
    end
    second_page(commits)
  end

  # The Github API returns 30 results at a time.
  # But what if there are more than 30 commits for this release?!
  # This adds the second page of results too, for a total of 60 commits.
  # There's no way anyone would have completed more than 60 issues.
  def second_page(commits)
    begin
      commits.concat @client.get(@client.last_response.rels[:next].href)
    rescue NoMethodError
      return commits
    end
    commits
  end

  def file(path:, ref: ENV["GITHUB_BASE_REF"])
    locations_file = @client.contents(@repo_name, path:, ref:)
    { sha: locations_file[:sha], contents: Base64.decode64(locations_file[:content]) }
  rescue Octokit::NotFound
    puts "Unable to find a file at '#{path}' in branch '#{ref}'"
    nil
  end

  # def update_file(commit_message:, file_contents:, file_path:, sha: nil, branch: ENV["GITHUB_HEAD_REF"])
  #   # The sha is the blob sha of the file (or files).
  #   # It's expected to be the sha of the CHANGELOG file on the main branch (GITHUB_BASE_REF)
  #   # Committing into the release branch

  #   @client.create_contents(@repo_name, file_path, commit_message, file_contents, { branch: }) if sha.nil?

  #   @client.update_contents(@repo_name, file_path, commit_message, sha, file_contents, { branch: })
  #   true
  # rescue Octokit::Conflict
  #   # Rerunning the Action can cause an error.
  #   # There's a risk of creating a new "Prepare for release" commit with an empty CHANGELOG section
  #   puts "Octokit::Conflict error. 409 - CHANGELOG does not match sha"
  #   puts "Did this Action get run multiple times?"
  #   false
  # end

  def issue_labels(issue:)
    issue = issue.to_i if issue.is_a? String
    # The response object stores various data about each label, as a hash
    begin
      @client.labels_for_issue(@repo_name, issue).map { |label| label[:name] }
    rescue Octokit::NotFound
      puts "Issue ##{issue} not found."
      []
    end
  end

  def ref(branch_name:)
    @client.ref(@repo_name, "heads/#{branch_name}")
  end

  def make_blob(text:)
    @client.create_blob(@repo_name, text)
  end

  def git_commit(sha:)
    @client.git_commit(@repo_name, sha)
  end

  def make_tree(tree_data:, base_tree_sha:)
    @client.create_tree(@repo_name, tree_data, base_tree: base_tree_sha)
  end

  def make_commit(commit_message:, tree_sha:, base_commit_sha:)
    @client.create_commit(@repo_name, commit_message, tree_sha, base_commit_sha)
  end

  def update_ref(branch_name:, commit_sha:)
    @client.update_ref(@repo_name, "heads/#{branch_name}", commit_sha)
  end

  def comment_on_pr_or_issue(number:, text: "Hello World!")
    number = number.to_i if number.is_a? String
    @client.add_comment(@repo_name, number, text)
  end
end
