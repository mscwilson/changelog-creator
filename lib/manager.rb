class Manager
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
