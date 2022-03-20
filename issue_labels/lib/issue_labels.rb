require "octokit"

client = Octokit::Client.new(access_token: ENV["ACCESS_TOKEN"])

user = client.user "mscwilson"
puts user.name
puts user.fields
puts user.login

client.add_labels_to_an_issue("mscwilson/changelog-test", 11, ["I will be astonished if this works"])

puts "Hello from issue_labels"
puts "Maybe this is? #{ENV['MY_ENV']}"
puts "And this is? #{ENV['OTHER_ENV']}"
