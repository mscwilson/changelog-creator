require "octokit"

client = Octokit::Client.new(access_token: ENV["ACCESS_TOKEN"])

# user = client.user "mscwilson"
# puts user.name
# puts user.fields
# puts user.login

# client.add_labels_to_an_issue("mscwilson/changelog-test", 11, ["I will be astonished if this works"])

events = client.repository_events(ENV['GITHUB_REPOSITORY'])
puts events[0].fields
puts events[0][:actor]
