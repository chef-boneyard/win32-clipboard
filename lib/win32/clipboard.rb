require 'windows/clipboard'
require 'windows/memory'
require 'windows/error'
require 'windows/shell'
require 'windows/library'
require 'windows/window'
require 'windows/msvcrt/buffer'
require 'windows/gdi/metafile'
require 'windows/window/message'
require 'windows/window/classes'

# The Win32 module serves as a namespace only.
module Win32
   # The Clipboard class encapsulates functions that relate to the MS Windows
   # clipboard.
   class Clipboard
      # The Clipboard::Error class is raised if any of the Win32::Clipboard
      # methods should fail.
      class Error < StandardError; end
      
      include Windows::Clipboard
      include Windows::Memory
      include Windows::Error
      include Windows::Window::Classes
      include Windows::Window::Message

      extend Windows::Clipboard
      extend Windows::Memory
      extend Windows::Error
      extend Windows::Shell
      extend Windows::Library
      extend Windows::Window
      extend Windows::MSVCRT::Buffer
      extend Windows::GDI::MetaFile
      extend Windows::Window::Message
      extend Windows::Window::Classes
      
      # The version of this library
      VERSION = '0.5.2'
      
      # Clipboard formats
      
      # Text
      TEXT = CF_TEXT
      OEMTEXT = CF_OEMTEXT
      UNICODETEXT = CF_UNICODETEXT

      # Images
      DIB = CF_DIB
      BITMAP = CF_BITMAP
      
      # Metafiles
      ENHMETAFILE = CF_ENHMETAFILE
      
      # Files
      HDROP = CF_HDROP

      # Sets the clipboard contents to the data that you specify. You may
      # optionally specify a clipboard format. The default is Clipboard::TEXT.
      #
      # Example:
      #
      #    # Put the string 'hello' on the clipboard
      #    Win32::Clipboard.set_data('hello')
      # 
      def self.set_data(clip_data, format = TEXT)
         self.open
         EmptyClipboard()

         # NULL terminate text
         case format
            when TEXT, OEMTEXT, UNICODETEXT				
               clip_data << "\0"
         end

         # Global Allocate a movable piece of memory.
         hmem = GlobalAlloc(GHND, clip_data.length + 4)
         mem  = GlobalLock(hmem)
         memcpy(mem, clip_data, clip_data.length)

         # Set the new data
         begin
            if SetClipboardData(format, hmem) == 0
               raise Error, "SetClipboardData() failed: " + get_last_error
            end
         ensure
            GlobalFree(hmem)
            self.close
         end

         self
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
            self.open
            if IsClipboardFormatAvailable(format)
               handle = GetClipboardData(format)
               case format
                  when TEXT, OEMTEXT, UNICODETEXT
                     clip_data = 0.chr * GlobalSize(handle)
                     memcpy(clip_data, handle, clip_data.size)
                     clip_data = clip_data[ /^[^\0]*/ ]
                  when HDROP
                     clip_data = get_file_list(handle)
                  when ENHMETAFILE
                     clip_data = get_metafile_data(handle)
                  when DIB, BITMAP
                     clip_data = get_image_data(handle)
                  else
                     raise Error, 'format not supported'
               end
            else
               clip_data = ''
            end
         ensure
            self.close
         end

         clip_data
      end
      
      # Empties the contents of the clipboard.
      # 
      def self.empty
         begin
            self.open
            EmptyClipboard()
         ensure
            self.close
         end

         self
      end

      # Singleton aliases
      # 
      class << self
         alias :get_data :data
         alias :clear :empty
      end

      # Returns the number of different data formats currently on the
      # clipboard.
      # 
      def self.num_formats
         count = 0

         begin
            self.open
            count = CountClipboardFormats()
         ensure
            self.close
         end

         count
      end
      
      # Returns whether or not +format+ (an int) is currently available.
      # 
      def self.format_available?(format)
         IsClipboardFormatAvailable(format)
      end
      
      # Returns the corresponding name for the given +format_num+, or nil
      # if it does not exist. You cannot specify any of the predefined
      # clipboard formats (or nil is returned), only registered formats.
      # 
      def self.format_name(format_num)
         val = nil
         buf = 0.chr * 80

         begin
            self.open
            if GetClipboardFormatName(format_num, buf, buf.length) != 0
               val = buf
            end
         ensure
            self.close
         end

         val.split(0.chr).first rescue nil
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
               buf = 0.chr * 80
               GetClipboardFormatName(format, buf, buf.length)
               formats[format] = buf.split(0.chr).first
            end
         ensure
            self.close
         end

         formats
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
         raise TypeError unless format.is_a?(String)
         
         format_value = RegisterClipboardFormat(format)
         
         if format_value == 0
            error = "RegisterClipboardFormat() call failed: " + get_last_error
            raise Error, error
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
         handle = CreateWindow('static', name, 0, 0, 0, 0, 0, 0, 0, 0, 0)
         
         @first_notify = true

         wnd_proc = Win32::API::Callback.new('LLLL', 'L') do |hwnd, umsg, wparam, lparam|
            case umsg
               when WM_DRAWCLIPBOARD
                  yield unless @first_notify
                  next_viewer = GetWindowLongPtr(hwnd, GWL_USERDATA)
                  if next_viewer != 0
                     PostMessage(next_viewer, umsg, wparam, lparam)
                  end
                  rv = 0
               when WM_CHANGECBCHAIN
                  yield unless @first_notify
                  next_viewer = lparam if next_viewer == wparam
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

         old_wnd_proc = SetWindowLongPtr(handle, GWL_WNDPROC, wnd_proc.address)
         next_viewer  = SetClipboardViewer(handle)

         SetWindowLongPtr(handle, GWL_USERDATA, next_viewer)

         msg = 0.chr * 100

         while true
            while PeekMessage(msg, handle, 0, 0, 1)
               TranslateMessage(msg)
               DispatchMessage(msg)
            end
            sleep 0.1
         end
      end

      private

      # Opens the clipboard and prevents other applications from modifying
      # the clipboard content until it is closed.
      #
      def self.open
         if 0 == OpenClipboard(nil)
            raise Error, "OpenClipboard() failed: " + get_last_error
         end
      end

      # Close the clipboard
      #
      def self.close
         CloseClipboard()
      end
      
      # Get data for enhanced metadata files
      #
      def self.get_metafile_data(handle)
         buf_size = GetEnhMetaFileBits(handle, 0, nil)
         buf = 0.chr * buf_size
         GetEnhMetaFileBits(handle, buf_size, buf)
         buf
      end
      
      # Get data for bitmap files
      #
      def self.get_image_data(handle)       
         buf = nil
         bmi = 0.chr * 44 # BITMAPINFO

         begin
            address  = GlobalLock(handle)
            buf_size = GlobalSize(handle)

            memcpy(bmi, address, bmi.length)

            size        = bmi[0,4].unpack('L').first  # biSize
            bit_count   = bmi[14,2].unpack('S').first # biBitCount
            compression = bmi[16,4].unpack('L').first # biCompression
            size_image  = bmi[20,4].unpack('L').first # biSizeImage
            clr_used    = bmi[32,4].unpack('L').first # biClrUsed

            size_image = buf_size + 16 if size_image == 0

            # Calculate the header size
            case bit_count
               when 1
                  table_size = 2
               when 4
                  table_size = 16
               when 8
                  table_size = 256
               when 16, 32
                  if compression == 0
                     table_size = clr_used
                  elsif compression == 3
                     table_size = 3
                  else
                     raise Error, "invalid bit/compression combination"
                  end
               when 24
                  table_size = clr_used
               else
                  raise Error, "invalid bit count"
            end # case

            offset = 0x36 + (table_size * 4)
            buf = 0.chr * buf_size

            memcpy(buf, address, buf.size)

            buf = "\x42\x4D" + [size_image].pack('L') + 0.chr * 4 + [offset].pack('L') + buf
         ensure
            GlobalUnlock(handle)
         end

         buf
      end

      # Get and return an array of file names that have been copied.
      #
      def self.get_file_list(handle)
         array = []
         count = DragQueryFile(handle, 0xFFFFFFFF, nil, 0)

         0.upto(count - 1){ |i|
            length = DragQueryFile(handle, i, nil, 0) + 1
            buf = 0.chr * length
            DragQueryFile(handle, i, buf, buf.length)
            array << buf.strip
         }

         array
      end
   end
end