########################################################################
# test_html_clipboard.rb
#
# Test suite for the HtmlClipboard class.
########################################################################
gem 'test-unit'
require 'test/unit'
require 'win32/html_clipboard'

class TC_Html_Clipboard < Test::Unit::TestCase
   def setup
      @html_str  = "Writing to the <i>clipboard</i> is <b>easy</b> with this code"
      @plain_str = "Writing to the clipboard is easy with this code"
   end

   def test_cf_html_constant
      assert_not_nil(Win32::HtmlClipboard::CF_HTML)
      assert_kind_of(Integer, HtmlClipboard::CF_HTML)
   end

   def test_get_data_basic
      assert_respond_to(HtmlClipboard, :get_data)
   end

   def test_set_data_basic
      assert_respond_to(HtmlClipboard, :set_data)
   end

   def test_set_and_get_data
      assert_nothing_raised{ HtmlClipboard.set_data(@html_str) }
      assert_equal(@plain_str, HtmlClipboard.get_data)
   end

   def test_is_html_format
      assert_respond_to(HtmlClipboard, :html_format?)
      assert_boolean(HtmlClipboard.html_format?)
   end

   def test_data_details_basic
      assert_respond_to(HtmlClipboard, :data_details)
      assert_nothing_raised{ HtmlClipboard.data_details }
      assert_kind_of(String, HtmlClipboard.data_details)
   end

   def teardown
      @html_str  = nil
      @plain_str = nil
   end
end
