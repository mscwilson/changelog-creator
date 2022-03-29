require "json"
require "date"
require "net/http"
require "uri"

class ChangelogCreator
  COMMIT_MESSAGE_PATTERN = /\A([\w\s.,'"-:`@]+) \((?:close|closes|fixes|fix) \#(\d+)\)$/
  RELEASE_BRANCH_PATTERN = %r{release/(\d*\.*\d*\.*\d*\.*)}
  RELEASE_COMMIT_PATTERN = /Prepare for \d*\.*\d*\.*\d*\.*\ *release/
  EMAIL_PATTERN = /\w+@snowplowanalytics\.com/

  def simple_changelog_block(branch_name:, commits:)
    version = extract_version_number(branch_name)
    return "" if version.nil?

    relevant_commits = extract_relevant_commit_data(commits)
    title = "#{version} (#{Date.today.strftime('%Y-%m-%d')})"

    relevant_commits.map! do |commit|
      if commit[:snowplower?]
        "#{commit[:message]} (##{commit[:issue]})"
      else
        "#{commit[:message]} (##{commit[:issue]}) - thanks @#{commit[:author]}!"
      end
    end
    "Version #{title}\n-----------------------\n#{relevant_commits.join("\n")}\n"
  end

  def extract_relevant_commit_data(commits)
    new_commits = commits.take_while { |commit| !RELEASE_COMMIT_PATTERN.match(commit["commit"]["message"]) }
    new_commits.map { |commit| process_single_commit(commit) }.compact
  end

  def extract_version_number(branch_name)
    version = branch_name.match(RELEASE_BRANCH_PATTERN)[1]
    version.count(".") == 1 ? "#{version}.0" : version
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
