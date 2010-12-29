require "rake/testtask"

Rake::TestTask.new do |t|
  t.libs << "test"
  t.ruby_opts = ['-rubygems']
  t.test_files = FileList["test/**/test_*.rb"]
  t.verbose = true
end

Rake::TestTask.new("test:unit") do |t|
  t.libs << "test"
  t.ruby_opts = ['-rubygems']
  t.test_files = FileList["test/cases/**/test_*.rb"]
  t.verbose = true
end

Rake::TestTask.new("test:integration") do |t|
  t.libs << "test"
  t.ruby_opts = ['-rubygems']
  t.test_files = FileList["test/integration/test_*.rb"]
  t.verbose = true
end
