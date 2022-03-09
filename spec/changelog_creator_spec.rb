require "changelog_creator"

describe ChangelogCreator do

  it "gets commits from a file" do
    creator = ChangelogCreator.new
    filename = "./lib/example_commits.json"
    results = creator.read_commits(filename)
    expect(results[0]["commit"]["author"]["name"]).to eq "Miranda Wilson"
  end

  xit "checks file is valid"

  xit "removes unwanted commits"
  xit "strips extra parts of the commit message"
  xit "gets the current date"
  xit "creates formatted commits for the current release"
  xit "appends commits to an existing changelog"
  xit "checks that all the release commits are present"
  xit "thanks external contributors"

end
