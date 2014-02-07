require File.join(File.dirname(__FILE__), 'windows', 'constants')
require File.join(File.dirname(__FILE__), 'windows', 'structs')
require File.join(File.dirname(__FILE__), 'windows', 'functions')

# The Win32 module serves as a namespace only.
module Win32

  # The Clipboard class encapsulates functions that relate to the MS Windows clipboard.
  class Clipboard

    include Windows::Constants
    include Windows::Structs
    include Windows::Functions

    extend Windows::Functions
    extend Windows::Structs

    # The version of this library
    VERSION = '0.6.3'

    # Clipboard formats

    # Text

    TEXT = 1
    OEMTEXT = 7
    UNICODETEXT = 13

    # Images

    DIB = 8
    BITMAP = 2

    # Metafiles

    ENHMETAFILE = 14

    # Files

    HDROP = 15

    # Empties the contents of the clipboard.
    #
    def self.empty
      begin
        open
        clear_if_already_opened
      ensure
        close
      end
    end

    class << self
      alias clear empty
    end

    # Returns the number of different data formats currently on the clipboard.
    #
    def self.num_formats
      CountClipboardFormats() || 0
    end

    # Returns whether or not +format+ (an integer) is currently available.
    #
    def self.format_available?(format)
      IsClipboardFormatAvailable(format)
    end

    # Returns the data currently in the clipboard. If +format+ is
    # specified, it will attempt to retrieve the data in that format. The
    # default is Clipboard::TEXT.
    #
    # If there is no data in the clipboard, or data is available but the
    # format doesn't match the data, then an empty string is returned.
    #
    # Examples:
    #
    #    # Get some plain text
    #    Win32::Clipboard.data # => e.g. 'hello'
    #
    #    # Get a list of files copied from the Windows Explorer window
    #    Win32::Clipboard.data(Clipboard::HDROP) # => ['foo.rb', 'bar.rb']
    #
    #    # Get a bitmap and write it to another file
    #    File.open('bitmap_copy', 'wb'){ |fh|
    #       fh.write Win32::Clipboard.data(Clipboard::DIB)
    #    }
    #
    def self.data(format = TEXT)
      begin
        open

        if IsClipboardFormatAvailable(format)
          handle = GetClipboardData(format)

          case format
            when UNICODETEXT
              size = GlobalSize(handle)
              ptr  = GlobalLock(handle)
              clip_data = ptr.read_bytes(size).force_encoding('UTF-16LE').encode('UTF-8').strip
            when TEXT, OEMTEXT
              size = GlobalSize(handle)
              ptr  = GlobalLock(handle)

              clip_data = ptr.read_bytes(size).strip

              unless clip_data.ascii_only?
                clip_data.force_encoding('BINARY')
              end
            when HDROP
              clip_data = get_file_list(handle)
            when ENHMETAFILE
              clip_data = get_metafile_data(handle)
            when DIB, BITMAP
              clip_data = get_image_data(handle)
            else
              raise "format '#{format}' not supported"
          end
        else
          clip_data = ''
        end
      ensure
        close
      end

      clip_data
    end

    class << self
      alias get_data data
    end

    # Sets the clipboard contents to the data that you specify. You may
    # optionally specify a clipboard format. The default is Clipboard::TEXT.
    #
    # Example:
    #
    #    # Put the string 'hello' on the clipboard
    #    Win32::Clipboard.set_data('hello')
    #
    #    # Put the image test.bmp on the clipboard
    #    f = File.open("test.bmp", "rb")
    #    str = f.read
    #    Clipboard.set_data(str, Win32::Clipboard::DIB)
    #
    def self.set_data(clip_data, format = TEXT)
      begin
        open
        clear_if_already_opened

        # NULL terminate text or strip header of bitmap file
        case format
          when UNICODETEXT
            clip_data.encode!('UTF-16LE')
            clip_data << "\0".encode('UTF-16LE')
            buf = clip_data
            extra = 4
          when TEXT, OEMTEXT
            clip_data << "\0"
            buf = clip_data
            extra = 4
          when BITMAP, DIB
            buf = clip_data[BITMAP_FILE_HEADER_SIZE..clip_data.length]
            extra = 0
        end

        # Global Allocate a movable piece of memory.
        hmem = GlobalAlloc(GHND, buf.bytesize + extra)
        mptr = GlobalLock(hmem)

        mptr.write_bytes(buf, 0, buf.bytesize)

        # Set the new data
        if SetClipboardData(format, hmem) == 0
          raise SystemCallError.new('SetClipboardData', FFI.errno)
        end
      ensure
        GlobalFree(hmem)
        close
      end
    end

    # Returns a hash of all the current formats, with the format number as
    # the key and the format name as the value for that key.
    #
    # Example:
    #
    #    Win32::Clipboard.formats # => {1 => nil, 49335 => "HTML Format"}
    #
    def self.formats
      formats = {}
      format = 0

      begin
        self.open
        while 0 != (format = EnumClipboardFormats(format))
          buf = FFI::MemoryPointer.new(:char, 80)
          GetClipboardFormatName(format, buf, buf.size)
          string = buf.read_string
          formats[format] = string.empty? ? nil : string
        end
      ensure
        self.close
      end

      formats
    end

    # Returns the corresponding name for the given +format_num+, or nil
    # if it does not exist. You cannot specify any of the predefined
    # clipboard formats (or nil is returned), only registered formats.
    #
    def self.format_name(format_num)
      val = nil
      buf = FFI::MemoryPointer.new(:char, 80)

      begin
        open

        if GetClipboardFormatName(format_num, buf, buf.size) != 0
          val = buf.read_string
        end
      ensure
        close
      end

      val
    end

    # Registers the given +format+ (a String) as a clipboard format, which
    # can then be used as a valid clipboard format. Returns the integer
    # value of the registered format.
    #
    # If a registered format with the specified name already exists, a new
    # format is not registered and the return value identifies the existing
    # format. This enables more than one application to copy and paste data
    # using the same registered clipboard format. Note that the format name
    # comparison is case-insensitive.
    #
    # Registered clipboard formats are identified by values in the range 0xC000
    # through 0xFFFF.
    #
    def self.register_format(format)
      format_value = RegisterClipboardFormat(format)

      if format_value == 0
        raise SystemCallError.new('RegisterClipboardFormat', FFI.errno)
      end

      format_value
    end

    # Sets up a notification loop that will call the provided block whenever
    # there's a change to the clipboard.
    #
    # Example:
    #
    #    Win32::Clipboard.notify_change{
    #       puts "There's been a change in the clipboard contents!"
    #    }
    #--
    # We skip the first notification because the very act of attaching the
    # new window causes it to trigger once.
    #
    def self.notify_change(&block)
      name   = 'ruby-clipboard-' + Time.now.to_s
      handle = CreateWindowEx(0, 'static', name, 0, 0, 0, 0, 0, 0, 0, 0, nil)

      next_viewer = SetClipboardViewer(handle)

      if next_viewer.nil?
        raise SystemCallError.new('SetClipboardViewer', FFI.errno)
      end

      SetWindowLongPtr(handle, GWL_USERDATA, next_viewer)

      ObjectSpace.define_finalizer(self, proc{self.close_window(handle)})

      @first_notify = true

      wnd_proc = FFI::Function.new(:uintptr_t, [:uintptr_t, :uint, :uintptr_t, :uintptr_t]) do |hwnd, umsg, wparam, lparam|
        case umsg
           when WM_DESTROY
             next_viewer = GetWindowLongPtr(hwnd, GWL_USERDATA)
             ChangeClipboardChain(hwnd, next_viewer)
             PostQuitMessage(0)
             rv = 0
           when WM_DRAWCLIPBOARD
             yield unless @first_notify
             next_viewer = GetWindowLongPtr(hwnd, GWL_USERDATA)
             if next_viewer != 0
               PostMessage(next_viewer, umsg, wparam, lparam)
             end
             rv = 0
           when WM_CHANGECBCHAIN
             next_viewer = GetWindowLongPtr(hwnd, GWL_USERDATA)
             next_viewer = lparam if next_viewer == wparam
             SetWindowLongPtr(hwnd, GWL_USERDATA, next_viewer)
             if next_viewer != 0
               PostMessage(next_viewer, umsg, wparam, lparam)
             end
             rv = 0
           else
             rv = DefWindowProc(hwnd, umsg, wparam, lparam)
        end

        @first_notify = false

        rv
      end

      if SetWindowLongPtr(handle, GWL_WNDPROC, wnd_proc.address) == 0
        raise SystemCallError.new('SetWindowLongPtr', FFI.errno)
      end

      msg = FFI::MemoryPointer.new(:char, 100)

      while true
        while PeekMessage(msg, handle, 0, 0, 1)
          TranslateMessage(msg)
          DispatchMessage(msg)
        end
        sleep 0.1
      end
    end

    private

    # sizeof(BITMAPFILEHEADER)

    BITMAP_FILE_HEADER_SIZE = 14

    # sizeof(BITMAPINFOHEADER)

    BITMAP_INFO_HEADER_SIZE = 40

    # Opens the clipboard and prevents other applications from modifying
    # the clipboard content until it is closed.
    #
    def self.open
      unless OpenClipboard(0)
        raise SystemCallError.new('OpenClipboard', FFI.errno)
      end
    end

    # Close the clipboard
    #
    def self.close
      unless CloseClipboard()
        raise SystemCallError.new('CloseClipboard', FFI.errno)
      end
    end

    # Clear the clipboard that is already opened
    #
    def self.clear_if_already_opened
      unless EmptyClipboard()
        raise SystemCallError.new('EmptyClipboard', FFI.errno)
      end
    end

    # Get data for enhanced metadata files
    #
    def self.get_metafile_data(handle)
      buf_size = GetEnhMetaFileBits(handle, 0, nil)
      buf = FFI::MemoryPointer.new(:char, buf_size)
      GetEnhMetaFileBits(handle, buf.size, buf)
      buf.read_string
    end

    # Get data for bitmap files
    #
    def self.get_image_data(handle)
      buf = nil

      begin
        ptr = GlobalLock(handle)
        buf_size = GlobalSize(handle)

        bmi = BITMAPINFO.new(ptr)

        file_size = buf_size + BITMAP_FILE_HEADER_SIZE

        # Calculate the header size
        case bmi[:bmiHeader][:biBitCount]
          when 1
            table_size = 2
          when 4
            table_size = 16
          when 8
            table_size = 256
          when 16, 32
            if bmi[:bmiHeader][:biCompression] == BI_RGB
              table_size = bmi[:bmiHeader][:biClrUsed]
            elsif bmi[:bmiHeader][:biCompression] == BI_BITFIELDS
              table_size = bmi[:bmiHeader][:biClrUsed]
              if bmi[:bmiHeader][:biSize] == BITMAP_INFO_HEADER_SIZE
                # Add bit fields size
                table_size += 3
              end
            else
              raise "invalid bit/compression combination"
            end
          when 24
            table_size = bmi[:bmiHeader][:biClrUsed]
          else
            raise "invalid bit count"
        end # case

        # offset = sizeof(BITMAPFILEHEADER)
        #          + sizeof(BITMAPINFOHEADER or BITMAPV4HEADER or BITMAPV5HEADER)
        #          + (color table size)
        offset = BITMAP_FILE_HEADER_SIZE + bmi[:bmiHeader][:biSize] + (table_size * 4)

        buf = "\x42\x4D" + [file_size].pack('L') + 0.chr * 4 + [offset].pack('L') + ptr.read_bytes(buf_size)
      ensure
        GlobalUnlock(handle) if handle
      end

      buf
    end

    # Get and return an array of file names that have been copied.
    #
    def self.get_file_list(handle)
      array = []
      count = DragQueryFileA(handle, 0xFFFFFFFF, nil, 0)

      0.upto(count - 1){ |i|
        length = DragQueryFileA(handle, i, nil, 0) + 1
        buf = FFI::MemoryPointer.new(:char, length)
        DragQueryFileA(handle, i, buf, buf.size)
        array << buf.read_string
      }

      array
    end

    # Close a window.(for self.notify_change)
    #
    def self.close_window(handle)
      SendMessage(handle, WM_CLOSE, 0, 0)
    end
  end
end

require File.join(File.dirname(__FILE__), 'html_clipboard')
