# encoding: utf-8
###########################################################################
# test_clipboard_chain.rb
#
# Test suite for the win32-clipboard library(only clipboard chain).
###########################################################################
require 'test-unit'
require 'win32/clipboard'
require 'timeout'
require File.join(File.dirname(__FILE__), 'lock')

include Win32

class TC_Clipboard_Chain < Test::Unit::TestCase
  test "clipboard viewer chain" do
    begin
      # Add clipboard viewer 1-3
      # clipboard viewer chain: cv3 -> cv2 -> cv1
      cv1 = ClipboardViewer.new('1')
      puts 'Added clipboard viewer 1'

      cv2 = ClipboardViewer.new('2')
      puts 'Added clipboard viewer 2'

      cv3 = ClipboardViewer.new('3')
      puts 'Added clipboard viewer 3'

      lock do
        Clipboard.set_data('foo')
      end

      result = Clipboard.data
      assert_equal(result, cv1.result)
      assert_equal(result, cv2.result)
      assert_equal(result, cv3.result)

      # Remove clipboard viewer 2
      # clipboard viewer chain: cv3 -> cv1
      assert_not_nil(cv2.remove)

      cv1.clear
      cv3.clear
      Clipboard.set_data('bar')

      result = Clipboard.data
      assert_equal(result, cv1.result)
      assert_equal(result, cv3.result)

      # Remove clipboard viewer 3
      assert_not_nil(cv3.remove)

      cv1.clear
      Clipboard.set_data('foobar')

      result = Clipboard.data
      assert_equal(result, cv1.result)
      assert_not_nil(cv1.remove)
    ensure
      cv1.exit
      cv2.exit
      cv3.exit
    end
  end

  class ClipboardViewer
    NOTIFY_TIMEOUT = 20
    def initialize(key)
      @key = key
      load_path = File.join(File.join(File.dirname(__FILE__), '..'), 'lib')
      @pipe = IO.popen("#{RbConfig.ruby} -I #{load_path} #{File.join(File.dirname(__FILE__), "notify.rb")} #{key} #{NOTIFY_TIMEOUT}")
      @result = nil
      is_ready = false

      @t = Thread.start do
        begin
          while true
            result = @pipe.gets.chomp

            if result == 'ready'
              is_ready = true
            else
              @result = result
            end

            if @result == @key.chop
              break
            end
          end
        rescue => e
          puts $!
          puts e.backtrace
        end
      end

      Timeout::timeout(5) do
        until is_ready
          lock do
            Clipboard.set_data('ready')
          end
          sleep(0.1)
        end
      end
    end

    def clear
      @result = nil
    end

    def result
      Timeout::timeout(5) do
        until @result
          sleep(0.1)
        end
      end
      @result
    rescue Timeout::Error
      raise 'Cannot get result.(Timeout)'
    end

    def remove
      return unless @t.alive?
      lock do
        Clipboard.set_data(@key)
      end
      ret = @t.join(3)
      if ret
        @pipe.close
      end
      ret
    end

    def exit
      return unless @t.alive?
      Process.kill('KILL', @pipe.pid)
    end
  end
end
