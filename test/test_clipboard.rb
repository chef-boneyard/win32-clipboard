# encoding: utf-8
###########################################################################
# test_clipboard.rb
#
# Test suite for the win32-clipboard library.  This will copy and remove
# data from your clipboard. If your current clipboard data is crucial to
# you, please save it first.
#
# You should run this test case via the 'rake test' task.
###########################################################################
require 'test-unit'
require 'win32/clipboard'
include Win32

class TC_Win32_ClipBoard < Test::Unit::TestCase
  test "version is set to expected value" do
    assert_equal('0.7.0', Clipboard::VERSION)
  end

  test "data method basic functionality" do
    assert_respond_to(Clipboard, :data)
    assert_nothing_raised{ Clipboard.data }
    assert_kind_of(String, Clipboard.data)
  end

  test "data method requires proper format" do
    assert_raise(TypeError){ Clipboard.data('test') }
    assert_raise(NameError){ Clipboard.data(CF_FOO) }
  end

  test "get_data is an alias for data" do
    assert_respond_to(Clipboard, :get_data)
    assert_alias_method(Clipboard, :data, :get_data)
  end

  test "set_data basic functionality" do
    assert_respond_to(Clipboard, :set_data)
    assert_nothing_raised{ Clipboard.set_data('foo') }
  end

  test "set_data works with unicode text" do
    assert_nothing_raised{
      Clipboard.set_data('Ηελλας', Clipboard::UNICODETEXT)
    }
  end

  test "set_data requires at least one argument" do
    assert_raise(ArgumentError){ Clipboard.set_data }
  end

  test "set_data requires a valid data format" do
    assert_raise(NameError){ Clipboard.set_data('foo', CF_FOO) }
  end

  test "set and get ascii data as expected" do
    assert_nothing_raised{ Clipboard.set_data('foobar') }
    assert_equal('foobar', Clipboard.data)
  end

  test "set and get unicode data as expected" do
    assert_nothing_raised{
       Clipboard.set_data('Ηελλας', Clipboard::UNICODETEXT)
    }
    assert_equal('Ηελλας', Clipboard.data(Clipboard::UNICODETEXT))
  end

  test "empty method basic functionality" do
    assert_respond_to(Clipboard, :empty)
    assert_nothing_raised{ Clipboard.empty }
  end

  test "clear is an alias for empty" do
    assert_respond_to(Clipboard, :clear)
    assert_alias_method(Clipboard, :clear, :empty)
  end

  test "num_formats basic functionality" do
    assert_respond_to(Clipboard, :num_formats)
    assert_nothing_raised{ Clipboard.num_formats }
    assert_kind_of(Fixnum, Clipboard.num_formats)
  end

  test "num_formats returns an expected value" do
    assert_true(Clipboard.num_formats >= 0)
    assert_true(Clipboard.num_formats < 1000)
  end

  test "num_formats does not accept any arguments" do
    assert_raise(ArgumentError){ Clipboard.num_formats(true) }
  end

  test "register_format basic functionality" do
    assert_respond_to(Clipboard, :register_format)
    assert_nothing_raised{ Clipboard.register_format('Ruby') }
    assert_kind_of(Integer, Clipboard.register_format('Ruby'))
  end

  test "register_format requires a string argument" do
    assert_raises(TypeError){ Clipboard.register_format(1) }
  end

  test "formats method basic functionality" do
    assert_respond_to(Clipboard, :formats)
    assert_nothing_raised{ Clipboard.formats }
    assert_kind_of(Hash, Clipboard.formats)
  end

  # TODO: Why do these fail?
  #test "formats result contains expected values" do
  #  assert_true(Clipboard.formats.size > 0)
  #  assert_true(Clipboard.formats.include?(1))
  #end

  test "formats method does not accept any arguments" do
    assert_raise(ArgumentError){ Clipboard.formats(true) }
  end

  test "format_available basic functionality" do
    assert_respond_to(Clipboard, :format_available?)
    assert_nothing_raised{ Clipboard.format_available?(1) }
  end

  test "format_available returns a boolean value" do
    assert_boolean(Clipboard.format_available?(1))
  end

  test "format_name basic functionality" do
    assert_respond_to(Clipboard, :format_name)
    assert_nothing_raised{ Clipboard.format_name(1) }
  end

  test "format_name returns expected value" do
    assert_equal("HTML Format", Clipboard.format_name(49419))
    assert_nil(Clipboard.format_name(9999999))
  end

  test "format_name requires a numeric argument" do
    assert_raise(TypeError){ Clipboard.format_name('foo') }
  end

=begin
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
=end
end
