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

end
