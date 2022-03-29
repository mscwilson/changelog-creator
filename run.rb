require "./lib/github_api_connection"
require "octokit"
require "base64"

puts "hello from changelog-creator"

client = Octokit::Client.new(access_token: "hello")

# connection = GithubApiConnection.new(client: client, repo_name: "mscwilson/try-out-actions-here")
# # connection.add_file
# p connection.get_file(path: "./add_me_to_repo.md")
# p content = file[:content]
# p Base64.decode64(file)

connection = GithubApiConnection.new(client: client, repo_name: "snowplow/snowplow-java-tracker")
p connection.get_file(path: "CHANGELOG")
# # connection.add_file
# content = connection.get_file[:content]
# p Base64.decode64(content)
