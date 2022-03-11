require "json"
require "date"

# puts "Hello, #{ARGV[0]}"

class ChangelogCreator
  COMMIT_MESSAGE_PATTERN = /\A([\w\s.,'"-:`@]+)\((?:close|closes|fixes|fix) \#(\d+)\)$/
  EMAIL_PATTERN = /\w+@snowplowanalytics\.com/

  def read_commits(file_path)
    raise StandardError, "Must be a JSON file" if file_path[-5..] != ".json"

    JSON.parse(File.read(file_path))
  end

  def read_changelog(file_path)
    raise StandardError, "Must be a changelog file" if file_path[-9..] != "CHANGELOG"

    File.open(file_path).readlines.map(&:chomp)
  end

  # def parse_commit_message(message)
  #   match = message.match(COMMIT_MESSAGE_PATTERN)
  #   match.nil? ? nil : "#{match[1]}(#{match[2]})"
  # end

  def process_single_commit(commit)
    message_match = commit["commit"]["message"].match(COMMIT_MESSAGE_PATTERN)
    return nil if message_match.nil?

    email_match = commit["commit"]["author"]["email"].match(EMAIL_PATTERN)

    { message: message_match[1].strip,
      issue: message_match[2],
      author: commit["author"]["login"],
      snowplower?: email_match.nil? ? false : true }
  end

  def make_header(version)
    "#{version} (#{Date.today.strftime('%Y-%m-%d')})"
  end

  def generate_log_for_new_commits(commits_path, changelog_path, version)
    commits = extract_commit_data(read_commits(commits_path))
    existing_changelog = read_changelog(changelog_path)

    # Commits for the new version won't be in the changelog already
    new_commits = commits.take_while { |message| !existing_changelog.include? message }
    text_block(new_commits, version)
  end

  def text_block(array, version)
    "#{make_header(version)}\n-----------------------\n#{array.join("\n")}\n"
  end
end

# creator = ChangelogCreator.new
# puts creator.generate_log_for_new_commits(ARGV[0], ARGV[1], "0.12.0")
