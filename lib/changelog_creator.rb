require "json"

puts "Hello, #{ARGV[0]}"

class ChangelogCreator

  COMMIT_PATTERN = /([\w\s\.,'"-:\`@]+)\((?:close|closes|fixes|fix) (\#\d+)\)/

  def read_commits(file_path)
    raise StandardError.new "Must be a JSON file" if file_path[-5..-1] != ".json"

    JSON.parse(File.read(file_path))
  end

  def parse_message(message)
    match = message.match(COMMIT_PATTERN)
    match.nil? ? nil : "#{match[1]}(#{match[2]})"
  end

  def extract_messages(json)
    p json.map { |commit| parse_message(commit["commit"]["message"]) }.compact
  end

  def make_header(version)
    "#{version} (#{Date.today.strftime('%Y-%m-%d')})"
  end

end
