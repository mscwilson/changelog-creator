require "json"

puts "Hello, #{ARGV[0]}"

class ChangelogCreator

  def read_commits(file_path)
    file = File.read(file_path)
    JSON.parse(file)
  end

end
