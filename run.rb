# frozen_string_literal: true

require "dotenv/load"
require "octokit"

require "./lib/manager"
require "./lib/github_api_connection"
require "./lib/changelog_creator"

LOG_PATH = "./CHANGELOG"

def run
  puts "Starting Release Helper."
  puts "Specified operation was: '#{ENV['INPUT_OPERATION']}'."

  manager = Manager.new
  # manager.do_operation

  # client = manager.octokit
  # repo = ENV["GITHUB_REPOSITORY"]

  manager.prepare_for_release
  # p client.snowplower?("mscwilson")

  # # File.write("lib/test_file.txt", "this file was created automatically")
  # # File.write("lib/another_test_file.txt", "another test file")

  # current_branch =  client.ref(branch_name: "release/0.2.0")
  # base_branch_sha = current_branch.object.sha

  # file1 = client.file path: "READMEf.md", ref: base_branch_sha
  # # file2 = client.file path: "lib/version.rb", ref: base_branch_sha

  # file1_new_content = "#{file1[:contents]}. Isn't that cool?"
  # file2_new_content = "#{file2[:contents]}\nAdding more text.\n\nAnd some more."

  # new_contents = {
  #                  "lib/test_file.txt" => file1_new_content,
  #                  "lib/another_test_file.txt" => file2_new_content
  #                }

  # new_tree = new_contents.map do |path, new_content|
  #   Hash(
  #     path: path,
  #     mode: "100644",
  #     type: "blob",
  #     sha: client.make_blob(text: new_content)
  #   )
  # end

  # p new_tree

  # current_commit = client.git_commit(repo, base_branch_sha)

  # current_tree = current_commit.tree

  # new_tree = client.create_tree(repo, new_tree, base_tree: current_tree["sha"])
  # commit_message = "Update test files"
  # new_commit = client.create_commit(repo, commit_message, new_tree["sha"], current_commit["sha"])

  # client.update_ref(repo, "heads/issue/42-commit_multiple_files", new_commit["sha"])
end

run
