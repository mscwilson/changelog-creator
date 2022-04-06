require "manager"

describe Manager do
  before do
    @manager = Manager.new
  end

  it "checks it's a PR from a release branch into main" do
    allow(ENV).to receive(:[]).with("GITHUB_BASE_REF").and_return("main")
    allow(ENV).to receive(:[]).with("GITHUB_HEAD_REF").and_return("release/0.1.0")

    expect(@manager.pr_branches_release_and_main?).to be true
  end

  it "returns false if it's not the right kind of PR" do
    allow(ENV).to receive(:[]).with("GITHUB_BASE_REF").and_return("release/1.3.2")
    allow(ENV).to receive(:[]).with("GITHUB_HEAD_REF").and_return("issue/123-feature")

    expect(@manager.pr_branches_release_and_main?).to be false
  end

  it "gets the PR number" do
    allow(ENV).to receive(:[]).with("GITHUB_REF_NAME").and_return("78/merge")
    expect(@manager.pr_number).to eq 78
  end
end
