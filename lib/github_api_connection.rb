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

  def pr_opened_to_main?
    recent_event = repo_events[0]
    if recent_event["type"] != "PullRequestEvent" || recent_event["payload"]["action"] != "opened"
      puts "The most recent event was not PR creation"
      return false
    end

    base_ref = recent_event["payload"]["pull_request"]["base"]["ref"]
    return true if %w[main master].include?(base_ref)

    puts "This PR was not opened against main/master branch"
    false
  end

  def pr_branches
    pr = repo_events[0]["payload"]["pull_request"]
    head_ref = pr["head"]["ref"]
    base_ref = pr["base"]["ref"]
    { head_ref:, base_ref: }
  end

  def commits_from_branch(branch_name)
    @client.commits(@repo_name, sha: branch_name)
  end

  def get_file(path:)
    file = @client.contents(@repo_name, path:)
    { sha: file[:sha], contents: Base64.decode64(file[:content]) }
  end

  def update_file(commit_message:, file_contents:, file_path:, sha: nil, branch: nil)
    @client.update_contents(@repo_name, file_path, commit_message, sha, file_contents, { branch: })
  end
end
