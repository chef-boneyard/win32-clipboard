require "rubygems"

Gem::Specification.new do |spec|
  spec.name      = 'win32-clipboard'
  spec.version   = '0.6.1'
  spec.authors   = ['Daniel J. Berger', 'Park Heesob']
  spec.license   = 'Artistic 2.0'
  spec.email     = 'djberg96@gmail.com'
  spec.homepage  = 'http://github.com/djberg96/win32-clipboard'
  spec.summary   = 'A library for interacting with the Windows clipboard'
  spec.test_file = 'test/test_clipboard.rb'
  spec.files     = Dir['**/*'].reject{ |f| f.include?('git') }

  spec.extra_rdoc_files  = ['CHANGES', 'README', 'MANIFEST']
  spec.rubyforge_project = 'win32utils'

  spec.add_dependency('ffi')
  spec.add_development_dependency('test-unit')
  spec.add_development_dependency('rake')

  spec.description = <<-EOF
    The win32-clipboard library provides an interface for interacting
    with the Windows clipboard. It supports the ability to read and
    write text, images, files, and Windows metafiles.
  EOF
end
