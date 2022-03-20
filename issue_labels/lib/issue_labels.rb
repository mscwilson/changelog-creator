require "octokit"

client = Octokit::Client.new(access_token: ENV["ACCESS_TOKEN"])

# user = client.user "mscwilson"
# puts user.name
# puts user.fields
# puts user.login

client.add_labels_to_an_issue("mscwilson/changelog-test", 11, ["I will be astonished if this works"])

events = client.repository_events(ENV["GITHUB_REPOSITORY"])
puts events.size

recent_event = events[0].to_h

BRANCH_NAME_PATTERN = /[0-9]+/

if recent_event[:type] == "CreateEvent"
  ref = recent_event[:payload][:ref]
  type = recent_event[:payload][:ref_type]

  if type == "branch"
    issue_number = ref.match(BRANCH_NAME_PATTERN)[0]
    client.add_labels_to_an_issue(ENV["GITHUB_REPOSITORY"], issue_number, ["type:in_progress"])
  end

end


