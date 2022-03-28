require "json"
require "date"
require "net/http"
require "uri"

class ChangelogCreator
  COMMIT_MESSAGE_PATTERN = /\A([\w\s.,'"-:`@]+) \((?:close|closes|fixes|fix) \#(\d+)\)$/
  RELEASE_COMMIT_PATTERN = /Prepare for \d*\.*\d*\.*\d*\.*\ *release/
  EMAIL_PATTERN = /\w+@snowplowanalytics\.com/

  def extract_relevant_commit_data(commits_json)
    parsed_commits = JSON.parse(commits_json)
    new_commits = parsed_commits.take_while { |commit| !RELEASE_COMMIT_PATTERN.match(commit["commit"]["message"]) }
    new_commits.map { |commit| process_single_commit(commit) }.compact
  end

  private # ------------------------------

  def process_single_commit(commit)
    message_match = commit["commit"]["message"].match(COMMIT_MESSAGE_PATTERN)
    return nil if message_match.nil?

    email_match = commit["commit"]["author"]["email"].match(EMAIL_PATTERN)

    { message: message_match[1],
      issue: message_match[2],
      author: commit["author"]["login"],
      snowplower?: email_match.nil? ? false : true }
  end

  # COMMIT_MESSAGE_PATTERN = /\A([\w\s.,'"-:`@]+)\((?:close|closes|fixes|fix) \#(\d+)\)$/
  # EMAIL_PATTERN = /\w+@snowplowanalytics\.com/

  # def read_commits_from_file(file_path)
  #   raise StandardError, "Must be a JSON file" if file_path[-5..] != ".json"

  #   JSON.parse(File.read(file_path))
  # end

  # def read_changelog(file_path)
  #   raise StandardError, "Must be a changelog file" if file_path[-9..] != "CHANGELOG"

  #   File.open(file_path).readlines.map(&:chomp)
  # end

  # def fetch_commits(owner_name, repo_name, branch_name)
  #   uri = URI.parse("https://api.github.com/repos/#{owner_name}/#{repo_name}/commits?sha=#{branch_name}")
  #   response = Net::HTTP.get_response(uri)

  #   JSON.parse(response.body)
  # end

  # def fetch_issue_labels(owner_name, repo_name, issue_number)
  #   uri = URI.parse("https://api.github.com/repos/#{owner_name}/#{repo_name}/issues/#{issue_number}/labels")
  #   response = Net::HTTP.get_response(uri)

  #   JSON.parse(response.body)
  # end

  # def process_single_commit(commit_hash)
  #   message_match = commit_hash["commit"]["message"].match(COMMIT_MESSAGE_PATTERN)
  #   return nil if message_match.nil?

  #   email_match = commit_hash["commit"]["author"]["email"].match(EMAIL_PATTERN)

  #   { message: message_match[1].strip,
  #     issue: message_match[2],
  #     author: commit_hash["author"]["login"],
  #     snowplower?: email_match.nil? ? false : true }
  # end

  # def process_issue_labels(labels)
  #   possible_types = ["type:enhancement", "type:defect", "type:admin"]
  #   labels.map! { |label| label["name"] }

  #   { type: (labels & possible_types)[0],
  #     breaking_change?: labels.include?("category:breaking_change") ? true : false }
  # end

  # def make_header(version)
  #   "#{version} (#{Date.today.strftime('%Y-%m-%d')})"
  # end

  # def generate_log_for_new_commits(commits_path, changelog_path, version)
  #   p "hello"
  #   commits = extract_commit_data(read_commits_from_file(commits_path))
  #   existing_changelog = read_changelog(changelog_path)

  #   # Commits for the new version won't be in the changelog already
  #   new_commits = commits.take_while { |message| !existing_changelog.include? message }
  #   text_block(new_commits, version)
  # end

  # def text_block(array, version)
  #   "#{make_header(version)}\n-----------------------\n#{array.join("\n")}\n"
  # end
end

# creator = ChangelogCreator.new
# # puts creator.generate_log_for_new_commits(ARGV[0], ARGV[1], "0.12.0")

# api_results = creator.read_commits_from_file(ARGV[0])
