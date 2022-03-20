require "octokit"

client = Octokit::Client.new(access_token: ENV["ACCESS_TOKEN"])

events = client.repository_events(ENV["GITHUB_REPOSITORY"])

recent_event = events[0].to_h

BRANCH_NAME_PATTERN = /[0-9]+/
PR_COMMIT_PATTERN = /\A([\w\s.,'"-:`@]+)\((?:close|closes|fixes|fix) \#(\d+)\)$/

if recent_event[:type] == "CreateEvent"
  branch_name = recent_event[:payload][:ref]
  type = recent_event[:payload][:ref_type]

  if type == "branch"
    issue_number = branch_name.match(BRANCH_NAME_PATTERN)[0]
    client.add_labels_to_an_issue(ENV["GITHUB_REPOSITORY"], issue_number, ["status:in_progress"])
  end

end

if recent_event[:type] == "PullRequestEvent"
  action = recent_event[:payload][:action]
  title = recent_event[:payload][:pull_request][:title]
  issue_number = title.match(PR_COMMIT_PATTERN)[2]

  if action == "opened"
    client.add_labels_to_an_issue(ENV["GITHUB_REPOSITORY"], issue_number, ["status:has_pr"])
  elsif action == "closed"
    client.add_labels_to_an_issue(ENV["GITHUB_REPOSITORY"], issue_number, ["status:completed"])
  end

end
