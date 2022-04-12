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
  manager.do_operation
end

run
