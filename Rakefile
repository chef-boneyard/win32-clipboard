require 'rake'
require 'rake/testtask'

desc "Install the win32-clipboard library (non-gem)"
task :install do
   dest = File.join(Config::CONFIG['sitelibdir'], 'win32')
   Dir.mkdir(dest) unless File.exists? dest
   cp 'lib/win32/clipboard.rb', dest, :verbose => true
end

desc "Install the win32-clipboard library as a gem"
task :install_gem do
   ruby 'win32-clipboard.gemspec'
   file = Dir["*.gem"].first
   sh "gem install #{file}"
end

desc "Run the example program"
task :example do
   sh "ruby -Ilib examples/clipboard_test.rb"end

Rake::TestTask.new do |t|
   t.warning = true
   t.verbose = true
end
