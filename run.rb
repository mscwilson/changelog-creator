require "dotenv/load"

require "./lib/manager"

LOG_PATH = "./CHANGELOG"

def run
  puts "Starting Release Helper."
  puts "Specified operation was: '#{ENV['INPUT_OPERATION']}'."

  manager = Manager.new
  manager.do_operation
end

run
