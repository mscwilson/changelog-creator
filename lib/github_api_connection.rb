require "octokit"
require "json"
require "base64"

class GithubApiConnection
  def initialize(client: Octokit::Client.new(access_token: ENV["ACCESS_TOKEN"]), repo_name: ENV["GITHUB_REPOSITORY"])
    @client = client
    @repo_name = repo_name
  end

  def repo_events
    # NB there can be a delay for a new PR to show up at the "events" endpoint
    @client.repository_events(@repo_name)
  end

  def repo_pull_requests
    @client.pull_requests(@repo_name)
  end

  def commits_from_branch(branch_name:)
    commits = @client.commits(@repo_name, sha: branch_name)

    # The Github API returns 30 results at a time
    # But what if there are more than 30 commits for this release?!
    # This adds the second page of results too, for a total of 60 commits.
    # There's no way anyone would have completed more than 60 issues
    begin
      commits.concat @client.get(@client.last_response.rels[:next].href)
    rescue NoMethodError
      return commits
    end
    commits
  end

  def get_file(path:, ref: ENV["GITHUB_BASE_REF"])
    file = @client.contents(@repo_name, path:, ref:)
    p Base64.decode64(file[:content])
    { sha: file[:sha], contents: Base64.decode64(file[:content]) }
  end

  def update_file(commit_message:, file_contents:, file_path:, sha: nil, branch: nil)
    @client.update_contents(@repo_name, file_path, commit_message, sha, file_contents, { branch: })
  rescue Octokit::Conflict
    puts "Octokit::Conflict error. 409 - CHANGELOG does not match sha"
    puts "Dunno what to tell you 🤷🏼‍♀️"
  end

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

  def comment_on_pr_or_issue(number:, text: "Hello World!")
    number = number.to_i if number.is_a? String
    @client.add_comment(@repo_name, number, text)
  end
end
