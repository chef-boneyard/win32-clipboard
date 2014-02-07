require 'win32/clipboard'
require File.join(File.dirname(__FILE__), 'lock')

include Win32

timeout = ARGV[1].to_i

def write
  data = ''
  lock do
    data = Clipboard.data
  end

  begin
    STDOUT.puts data
    STDOUT.flush
  rescue => e
    puts $!
  end
  if data == ARGV[0]
    exit
  end
end

Timeout::timeout(timeout) do
  Clipboard.notify_change {write}
end
