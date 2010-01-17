###########################################################################
# test_clipboard.rb
#
# Test suite for the win32-clipboard library.  This will copy and remove
# data from your clipboard. If your current clipboard data is crucial to
# you, please save it first.
#
# You should run this test case via the 'rake test' task.
###########################################################################
require 'rubygems'
gem 'test-unit'

require 'win32/clipboard'
require 'test/unit'
include Win32

class TC_Win32_ClipBoard < Test::Unit::TestCase  
   def test_version
      assert_equal('0.5.2', Clipboard::VERSION)
   end
     
   def test_data
      assert_respond_to(Clipboard, :data)
      assert_nothing_raised{ Clipboard.data }     
      assert_kind_of(String, Clipboard.data)
   end
   
   def test_data_expected_errors
      assert_raise(TypeError){ Clipboard.data('test') }
      assert_raise(NameError){ Clipboard.data(CF_FOO) }
   end
   
   def test_get_data_alias
      assert_respond_to(Clipboard, :get_data)
      assert_true(Clipboard.method(:data) == Clipboard.method(:get_data))
   end
   
   def test_set_data
      assert_respond_to(Clipboard, :set_data)
      assert_nothing_raised{ Clipboard.set_data("foo") }
   end
   
   def test_set_data_unicode
      assert_nothing_raised{
         Clipboard.set_data('Ηελλας', Clipboard::UNICODETEXT)
      }
   end
   
   def test_set_data_expected_errors
      assert_raise(ArgumentError){ Clipboard.set_data }
      assert_raise(NameError){ Clipboard.set_data('foo', CF_FOO) }
   end
   
   def test_set_and_get_ascii
      assert_nothing_raised{ Clipboard.set_data('foobar') }
      assert_equal('foobar', Clipboard.data)
   end
   
   def test_set_and_get_unicode
      assert_nothing_raised{
         Clipboard.set_data('Ηελλας', Clipboard::UNICODETEXT)
      }
      assert_equal('Ηελλας', Clipboard.data(Clipboard::UNICODETEXT))
   end
   
   def test_empty
      assert_respond_to(Clipboard, :empty)
      assert_nothing_raised{ Clipboard.empty }
   end
   
   def test_clear_alias
      assert_respond_to(Clipboard, :clear)
      assert_true(Clipboard.method(:clear) == Clipboard.method(:empty))      
   end
   
   def test_num_formats
      assert_respond_to(Clipboard, :num_formats)
      assert_nothing_raised{ Clipboard.num_formats }
      assert_kind_of(Fixnum, Clipboard.num_formats)
   end
   
   def test_num_formats_expected_errors
      assert_raise(ArgumentError){ Clipboard.num_formats(true) }
   end

   def test_register_format
      assert_respond_to(Clipboard, :register_format)
      assert_nothing_raised{ Clipboard.register_format('Ruby') }
      assert_kind_of(Integer, Clipboard.register_format('Ruby'))
   end
   
   def test_register_format_expected_errors
      assert_raises(TypeError){ Clipboard.register_format(1) }
   end
   
   def test_formats
      assert_respond_to(Clipboard, :formats)
      assert_nothing_raised{ Clipboard.formats }
      assert_kind_of(Hash, Clipboard.formats)
   end
   
   def test_formats_expected_errors
      assert_raise(ArgumentError){ Clipboard.formats(true) }      
   end
   
   def test_format_available
      assert_respond_to(Clipboard, :format_available?)
      assert_nothing_raised{ Clipboard.format_available?(1) }
      assert_boolean(Clipboard.format_available?(1))
   end
   
   def test_format_name
      assert_respond_to(Clipboard, :format_name)
      assert_nothing_raised{ Clipboard.format_name(1) }
      assert_nil(Clipboard.format_name(9999999))
   end
   
   def test_format_name_expected_errors
      assert_raise(TypeError){ Clipboard.format_name('foo') }
   end
   
   def test_notify_change
      assert_respond_to(Clipboard, :notify_change)
   end
   
   def test_constants
      assert_not_nil(Clipboard::TEXT)
      assert_not_nil(Clipboard::OEMTEXT)
      assert_not_nil(Clipboard::UNICODETEXT)
      assert_not_nil(Clipboard::BITMAP)
      assert_not_nil(Clipboard::DIB)
      assert_not_nil(Clipboard::HDROP)
      assert_not_nil(Clipboard::ENHMETAFILE)
   end 
end
