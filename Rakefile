require 'rake'
require 'rake/clean'
require 'rake/testtask'

CLEAN.include('**/*.gem', '**/*.rbc')

namespace :gem do
  desc "Create the win32-clipboard gem"
  task :create => [:clean] do
    require 'rubygems/package'
    spec = eval(IO.read('win32-clipboard.gemspec'))
    spec.signing_key = File.join(Dir.home, '.ssh', 'gem-private_key.pem')
    Gem::Package.build(spec)
  end

  desc "Install the win32-clipboard library"
  task :install => [:create] do
    file = Dir["*.gem"].first
    sh "gem install -l #{file}"
  end
end

desc "Run the example program"
task :example do
  sh "ruby -Ilib examples/clipboard_test.rb"
end

namespace :test do
  Rake::TestTask.new(:all) do |t|
    t.warning = true
    t.verbose = true
  end

  Rake::TestTask.new(:html) do |t|
    t.warning = true
    t.verbose = true
    t.test_files = FileList['test/test_html_clipboard.rb']
  end

  Rake::TestTask.new(:std) do |t|
    t.warning = true
    t.verbose = true
    t.test_files = FileList['test/test_clipboard.rb']
  end

  Rake::TestTask.new(:image) do |t|
    t.warning = true
    t.verbose = true
    t.test_files = FileList['test/test_image_clipboard.rb']
  end

  Rake::TestTask.new(:chain) do |t|
    t.warning = true
    t.verbose = true
    t.test_files = FileList['test/test_clipboard_chain.rb']
  end
end

task :default => 'test:all'
