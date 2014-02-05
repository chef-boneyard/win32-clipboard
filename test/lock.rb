require 'timeout'
require 'tmpdir'

def lock(&block)
  Timeout::timeout(5) do
    open(File.join(Dir.tmpdir, 'ruby-win32-clipboard.lock'), 'w') do |f|
      begin
        f.flock(File::LOCK_EX)
        yield
      ensure
        f.flock(File::LOCK_UN)
      end
    end
  end
rescue Timeout::Error
  raise 'Lock(timeout)'
end

