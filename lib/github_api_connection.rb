require "octokit"
require "json"
require "base64"

class GithubApiConnection
  def initialize(client: Octokit::Client.new(access_token: ENV["ACCESS_TOKEN"]), repo_name: ENV["GITHUB_REPOSITORY"])
    @client = client
    @repo_name = repo_name
  end

  def repo_events
    @client.repository_events(@repo_name)
  end

  def pr_opened_to_main?(events)
    recent_event = events[0]
    if recent_event["type"] != "PullRequestEvent" || recent_event["payload"]["action"] != "opened"
      puts "The most recent event was not PR creation"
      return false
    end

    branches = pr_branches(recent_event)
    unless %w[main master].include?(branches[:base_ref])
      puts "This PR was not opened against main/master branch"
      return false
    end

    unless branches[:head_ref][0..6] == "release"
      puts "This PR was not opened from a release branch"
      return false
    end

    true
  end

  def pr_branches(pull_request_event)
    pr = pull_request_event["payload"]["pull_request"]
    head_ref = pr["head"]["ref"]
    base_ref = pr["base"]["ref"]
    { head_ref:, base_ref: }
  end

  def commits_from_branch(branch_name:)
    commits = @client.commits(@repo_name, sha: branch_name)

    # The Github API returns 30 results at a time
    # But what if there are more than 30 commits for this release?!
    # This adds the second page of results too, for a total of 60 commits
    # There's no way anyone would have completed more than 60 issues
    begin
      commits.concat @client.get(@client.last_response.rels[:next].href)
    rescue NoMethodError
      return commits
    end
    commits
  end

  def get_file(path:, ref: nil)
    file = @client.contents(@repo_name, path:, ref:)
    { sha: file[:sha], contents: Base64.decode64(file[:content]) }
  end

  def update_file(commit_message:, file_contents:, file_path:, sha: nil, branch: nil)
    @client.update_contents(@repo_name, file_path, commit_message, sha, file_contents, { branch: })
  end
end
