########################################################################
# test_html_clipboard.rb
#
# Test suite for the HtmlClipboard class.
########################################################################
require 'test-unit'
require 'win32/clipboard'
require 'win32/html_clipboard'
include Win32

class TC_Html_Clipboard < Test::Unit::TestCase
  def setup
    @html_str  = "Writing to the <i>clipboard</i> is <b>easy</b> with this code"
    @plain_str = "Writing to the clipboard is easy with this code"
  end

  test "CF_HTML constant is defined" do
    assert_not_nil(HtmlClipboard::CF_HTML)
    assert_kind_of(Integer, HtmlClipboard::CF_HTML)
  end

  test "get_data basic functionality" do
    assert_respond_to(HtmlClipboard, :get_data)
  end

  test "set_data basic functionality" do
    assert_respond_to(HtmlClipboard, :set_data)
  end

  test "getting html data returns a plain string" do
    assert_nothing_raised{ HtmlClipboard.set_data(@html_str) }
    assert_equal(@plain_str, HtmlClipboard.get_data)
  end

  test "html_format basic functionality" do
    assert_respond_to(HtmlClipboard, :html_format?)
    assert_boolean(HtmlClipboard.html_format?)
  end

  test "data details basic functionality" do
    assert_respond_to(HtmlClipboard, :data_details)
    assert_nothing_raised{ HtmlClipboard.data_details }
    assert_kind_of(String, HtmlClipboard.data_details)
  end

  def teardown
    @html_str  = nil
    @plain_str = nil
  end
end
