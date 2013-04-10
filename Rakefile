# encoding: utf-8

require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << "lib"
  t.libs << "."
  t.verbose = true
  t.test_files = FileList["test/**/test_*.rb"]
end

desc "build the gem"
task :gem do
  sh "gem build curlicue.gemspec"
end
