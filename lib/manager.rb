class Manager
  def initialize(access_token: ENV["ACCESS_TOKEN"],
                 client: Octokit::Client,
                 repo_name: ENV["GITHUB_REPOSITORY"],
                 api_connection: GithubApiConnection,
                 log_creator: ChangelogCreator)
    @octokit = api_connection.new(client: client.new(access_token:), repo_name:)
    @log_creator = log_creator.new(@octokit)
  end

  def do_operation
    case ENV["INPUT_OPERATION"]
    when "prepare for release", "prepare"
      prepare_for_release
    when "github release notes", "github"
      github_release_notes
    else
      puts "Unexpected string input. That's not a valid operation. Exiting action."
    end
  end

  def prepare_for_release
    "hello! I'm preparing for release!"
  end

  def github_release_notes
    "I'm creating GH release notes"
  end

  def pr_event?
    ENV["GITHUB_EVENT_NAME"] == "pull_request"
  end

  def pr_branches_release_and_main?
    puts "Checking it's a PR of the right sort..."
    unless %w[main master].include?(ENV["GITHUB_BASE_REF"])
      puts "This was not a PR opened against main/master branch."
      return false
    end

    unless ENV["GITHUB_HEAD_REF"][0..6] == "release"
      puts "This PR was not opened from a release branch."
      return false
    end
    puts "This PR was opened from a release branch into main/master. Continuing."
    true
  end

  def pr_number
    /\d+/.match(ENV["GITHUB_REF_NAME"])[0].to_i
  end
end
