require "rubygems"

spec = Gem::Specification.new do |gem|
   gem.name      = 'win32-clipboard'
   gem.version   = '0.5.2'
   gem.authors   = ['Daniel J. Berger', 'Park Heesob']
   gem.license   = 'Artistic 2.0'
   gem.email     = 'djberg96@gmail.com'
   gem.homepage  = 'http://www.rubyforge.org/projects/win32utils'
   gem.platform  = Gem::Platform::RUBY
   gem.summary   = 'A library for interacting with the Windows clipboard'
   gem.test_file = 'test/test_clipboard.rb'
   gem.has_rdoc  = true
   gem.files     = Dir['**/*'].reject{ |f| f.include?('CVS') }

   gem.extra_rdoc_files  = ['CHANGES', 'README', 'MANIFEST']
   gem.rubyforge_project = 'win32utils'

   gem.add_dependency('windows-pr', '>= 1.0.3')

   gem.description = <<-EOF
      The win32-clipboard library provides an interface for interacting
      with the Windows clipboard. It supports the ability to read and
      write text, images, files, and Windows metafiles.
   EOF
end

Gem::Builder.new(spec).build
