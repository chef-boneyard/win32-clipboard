# encoding: utf-8
###########################################################################
# test_image_clipboard.rb
#
# Test suite for the win32-clipboard library(only get_image_data).
###########################################################################
require 'test-unit'
require 'win32/clipboard'
include Win32

class TC_Image_ClipBoard < Test::Unit::TestCase
  class << self
    def startup
      @t = Thread.new do
        begin
          Win32::Clipboard.notify_change {$is_ready = true}
        rescue => e
          puts $!
          puts e.backtrace
        end
      end
    end

    def shutdown
      @t.kill
    end
  end

  dir = File.join(File.dirname(__FILE__), 'img')
  Dir.glob("#{dir}/*.bmp") do |file|
    test "get_image_data file: " + File.basename(file) do
      $is_ready = false

      bmp = File.open(file, "rb").read
      Clipboard.set_data(bmp, Clipboard::DIB)

      until $is_ready
        sleep 0.1
      end

      assert_equal(Clipboard.data(Clipboard::DIB), bmp)
    end
  end

end
