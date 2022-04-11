# frozen_string_literal: true

require "json"
require "date"
require "net/http"
require "uri"

require_relative "github_api_connection"

# Processes commits into CHANGELOG or release notes format
class ChangelogCreator
  COMMIT_MESSAGE_PATTERN = /\A([\w\s.,'"-:`@]+) \((?:close|closes|fixes|fix) \#(\d+)\)$/
  RELEASE_COMMIT_PATTERN = /Prepare for v*\d*\.*\d*\.*\d*\.*\ *release/
  MERGE_COMMIT_PATTERN = /Merge (pull request|branch)/
  EMAIL_PATTERN = /\w+@snowplowanalytics\.com/

  attr_reader :octokit

  def initialize(api_connection:)
    @octokit = api_connection
  end

  def relevant_commits(commits:, version:)
    allowed_message = "Prepare for #{version} release"
    commits.take_while do |commit|
      message = commit[:commit][:message]
      message.start_with?(allowed_message) || !prepare_for_release_commit?(message:)
    end
  end

  def useful_commit_data(commits:)
    # This processes the commits into hashes of useful stuff
    # It also removes any commits without an issue number
    commits.map { |commit| process_single_commit(commit) }.compact
  end

  def new_changelog_text(commit_data:, version:, original_text:)
    new_log_section = simple_changelog_block(version:, commit_data:)
    "#{new_log_section}\n#{original_text}"
  end

  def fancy_changelog(commit_data:)
    commits_by_type = sort_commits_by_type(commit_data)

    features = commits_by_type[:feature].empty? ? "" : "**New features**\n#{commits_by_type[:feature].join("\n")}\n\n"
    bugs = commits_by_type[:bug].empty? ? "" : "**Bug fixes**\n#{commits_by_type[:bug].join("\n")}\n\n"
    admin = commits_by_type[:admin].empty? ? "" : "**Under the hood**\n#{commits_by_type[:admin].join("\n")}\n\n"
    unlabelled = commits_by_type[:misc].empty? ? "" : "**Changes**\n#{commits_by_type[:misc].join("\n")}\n"

    "#{features}#{bugs}#{admin}#{unlabelled}"
  end

  private # ------------------------------

  def simple_changelog_block(commit_data:, version:)
    title = "#{version} (#{Date.today.strftime('%Y-%m-%d')})"

    commit_data.map! do |commit|
      if commit[:snowplower]
        "#{commit[:message]} (##{commit[:issue]})"
      else
        "#{commit[:message]} (##{commit[:issue]}) - thanks @#{commit[:author]}!"
      end
    end
    "Version #{title}\n-----------------------\n#{commit_data.join("\n")}\n"
  end

  def sort_commits_by_type(commit_data)
    # Type i.e. what label the issue had
    commits_by_type = commit_data.each_with_object(Hash.new([].freeze)) do |i, dict|
      case i[:type]
      when nil
        dict[:misc] += [i]
      when "feature"
        dict[:feature] += [i]
      when "bug"
        dict[:bug] += [i]
      when "admin"
        dict[:admin] += [i]
      end
    end

    sorted_commits_to_one_liners(commits_by_type)
  end

  def sorted_commits_to_one_liners(commits)
    commits.each do |k, _v|
      commits[k].map! { |commit| fancy_log_single_line(commit_data: commit) }
    end
  end

  def fancy_log_single_line(commit_data:)
    breaking_change = commit_data[:breaking_change] ? " **BREAKING CHANGE**" : ""
    thanks = commit_data[:snowplower] ? "" : " - thanks @#{commit_data[:author]}!"
    "#{commit_data[:message]} (##{commit_data[:issue]})#{thanks}#{breaking_change}"
  end

  def prepare_for_release_commit?(message:)
    RELEASE_COMMIT_PATTERN.match?(message)
  end

  def merge_commit?(message:)
    MERGE_COMMIT_PATTERN.match?(message)
  end

  def process_single_commit(commit)
    message_match = commit[:commit][:message].match(COMMIT_MESSAGE_PATTERN)
    return nil if message_match.nil?

    labels = @octokit.issue_labels(issue: message_match[2])
    label_data = parse_labels(labels:)

    { message: message_match[1],
      issue: message_match[2],
      author: commit[:author][:login],
      snowplower: @octokit.snowplower?(commit[:author][:login]),
      breaking_change: label_data[:breaking_change],
      type: label_data[:type] }
  end

  def parse_labels(labels:)
    result = { type: nil, breaking_change: false }
    if labels.include?("type:enhancement")
      result[:type] = "feature"
    elsif labels.include?("type:defect")
      result[:type] = "bug"
    elsif labels.include?("type:admin")
      result[:type] = "admin"
    end
    result[:breaking_change] = true if labels.include?("category:breaking_change")
    result
  end
end
