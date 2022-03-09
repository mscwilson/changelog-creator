require "json"

# puts "Hello, #{ARGV[0]}"

class ChangelogCreator

  COMMIT_PATTERN = /\A([\w\s\.,'"-:\`@]+)\((?:close|closes|fixes|fix) (\#\d+)\)$/

  def read_commits(file_path)
    raise StandardError.new "Must be a JSON file" if file_path[-5..-1] != ".json"

    JSON.parse(File.read(file_path))
  end

  def read_changelog(file_path)
    raise StandardError.new "Must be a changelog file" if file_path[-9..-1] != "CHANGELOG"

    File.open(file_path).readlines.map(&:chomp)
  end

  def parse_message(message)
    match = message.match(COMMIT_PATTERN)
    match.nil? ? nil : "#{match[1]}(#{match[2]})"
  end

  def extract_messages(json)
    json.map { |commit| parse_message(commit["commit"]["message"]) }.compact
  end

  def make_header(version)
    "#{version} (#{Date.today.strftime('%Y-%m-%d')})"
  end

  def generate_log_for_new_commits(commits_path, changelog_path, version)
    commits = extract_messages(read_commits(commits_path))
    existing_changelog = read_changelog(changelog_path)
    new_commits = commits.take_while { |message| !existing_changelog.include? message }
    "#{make_header(version)}\n-----------------------\n#{new_commits.join("\n")}\n"
  end

end
