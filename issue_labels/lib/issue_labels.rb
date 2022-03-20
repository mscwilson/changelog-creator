require "octokit"

client = Octokit::Client.new(access_token: ENV["ACCESS_TOKEN"])

# user = client.user "mscwilson"
# puts user.name
# puts user.fields
# puts user.login

# client.add_labels_to_an_issue("mscwilson/changelog-test", 11, ["I will be astonished if this works"])

events = client.repository_events(ENV["GITHUB_REPOSITORY"])
puts events.size

recent_event = events[0]
puts recent_event.fields
puts recent_event[:actor]
puts recent_event.actor

content = recent_event.content
puts content
puts "hmm"
puts content.to_h
