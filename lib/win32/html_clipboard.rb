require 'win32/clipboard'

# The Win32 module serves as a namespace only.
#
module Win32

  # The HtmlClipboard class is a subclass of Clipboard that explicitly
  # handles text in HTML format.
  #
  class HtmlClipboard < Clipboard

    private

    # Marker block output
    #--
    # Version: Version of the clipboard.
    #
    # StartHTML: bytecount from the beginning of the clipboard to the
    #    start of the context, or -1 if no context.
    #
    # EndHTML: bytecount from the beginning of the clipboard to the end
    #    of the context, or -1 if no context.
    #
    # StartFragment: bytecount from the beginning of the clipboard to
    #    the start of the fragment.
    #
    # EndFragment: bytecount from the beginning of the clipboard to the
    #    end of the fragment.
    #
    # StartSelection: bytecount from the beginning of the clipboard to
    #    the start of the selection.
    #
    # EndSelection: bytecount from the beginning of the clipboard to the
    #    end of the selection.
    #
    MARKER_BLOCK_OUTPUT =
      "Version:1.0\r\n" \
      "StartHTML:%09d\r\n" \
      "EndHTML:%09d\r\n" \
      "StartFragment:%09d\r\n" \
      "EndFragment:%09d\r\n" \
      "StartSelection:%09d\r\n" \
      "EndSelection:%09d\r\n" \
      "SourceURL:%s\r\n"

    # Extended marker block
    MARKER_BLOCK_EX =
      'Version:(\S+)\s+' \
      'StartHTML:(\d+)\s+' \
      'EndHTML:(\d+)\s+' \
      'StartFragment:(\d+)\s+' \
      'EndFragment:(\d+)\s+' \
      'StartSelection:(\d+)\s+' \
      'EndSelection:(\d+)\s+' \
      'SourceURL:(\S+)'

    # Regular expression for extended marker block
    MARKER_BLOCK_EX_RE = Regexp.new(MARKER_BLOCK_EX, Regexp::MULTILINE) # :nodoc:

    # Standard marker block
    MARKER_BLOCK =
      'Version:(\S+)\s+' \
      'StartHTML:(\d+)\s+' \
      'EndHTML:(\d+)\s+' \
      'StartFragment:(\d+)\s+' \
      'EndFragment:(\d+)\s+' \
      'SourceURL:(\S+)'

    # Regular expression for the standard marker block
    MARKER_BLOCK_RE = Regexp.new(MARKER_BLOCK, Regexp::MULTILINE)

    # Default HTML body
    DEFAULT_HTML_BODY =
      "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0 Transitional//EN\">\r\n" \
      "<HTML><BODY><!--StartFragment-->%s<!--EndFragment--></BODY></HTML>"

    public

    # Clipboard format value
    CF_HTML = RegisterClipboardFormat("HTML Format")

    def initialize # :nodoc:
      @html      = nil
      @fragment  = nil
      @selection = nil
      @source    = nil
      @version   = nil
    end

    # Returns a boolean indicating whether or not the clipboard contains
    # data in HTML format.
    #
    def self.html_format?
      format_available?(CF_HTML)
    end

    # This method is nearly identical to the Clipboard.data method, but
    # it decodes the data to preserve the HTML formatting.
    #
    def self.data
      begin
        self.open
        if IsClipboardFormatAvailable(CF_HTML)
          handle = GetClipboardData(CF_HTML)
          clip_data = 0.chr * GlobalSize(handle)
          memcpy(clip_data, handle, clip_data.size)
          clip_data[ /^[^\0]*/ ]
          clip_data = decode_data(clip_data)
        else
          clip_data = ''
        end
      ensure
        self.close
      end
      clip_data
    end

    # Returns the block marker information for the HTML, or an empty
    # string if there is no clipboard data.
    #
    def self.data_details
      clip_data = data
      string = ""
      unless clip_data.empty?
        string << "prefix=>>>#{@prefix}<<<END"
        string << "version=>>>#{@version}<<<END"
        string << "selection=>>>#{@selection}<<<END"
        string << "fragment=>>>#{@fragment}<<<END"
        string << "html=>>>#{@html}<<<END"
        string << "source=>>>#{@source}<<<END"
      end
      string
    end

    # Put a well-formed fragment of HTML on the clipboard.
    #
    # The +selection+, if provided, must be a literal string within a
    # fragment.
    #
    # The +html+ value, if provided, must be a well formed HTML document
    # that textually contains a fragment and its required markers.
    #
    # The +source+, if provided, should include a scheme (file, http, or
    # https) plus a file name. The default is file:// + __FILE__.
    #
    def self.set_data(fragment, selection=nil, html=nil, source=nil)
      selection ||= fragment
      html      ||= DEFAULT_HTML_BODY % fragment
      source    ||= 'file://' + __FILE__

      fragment_start  = html.index(fragment)
      fragment_end    = fragment_start + fragment.length
      selection_start = html.index(selection)
      selection_end   = selection_start + selection.length

      clip_data = encode_data(
        html,
        fragment_start,
        fragment_end,
        selection_start,
        selection_end,
        source
      )

      self.open
      EmptyClipboard()

      # Global Allocate a movable piece of memory.
      hmem = GlobalAlloc(GHND, clip_data.length + 4)
      mem  = GlobalLock(hmem)
      memcpy(mem, clip_data, clip_data.length)

      clip_data2 = fragment.gsub(/<[^>]+?>/,'')
      hmem2 = GlobalAlloc(GHND, clip_data2.length + 4)
      mem2  = GlobalLock(hmem2)
      memcpy(mem2, clip_data2, clip_data2.length)

      # Set the new data
      begin
        if SetClipboardData(CF_HTML, hmem) == 0
          raise SystemCallError.new('SetClipboardData', FFI.errno)
        end

        if SetClipboardData(CF_TEXT, hmem2) == 0
          raise SystemCallError.new('SetClipboardData', FFI.errno)
        end
      ensure
        GlobalFree(hmem)
        GlobalFree(hmem2)
        self.close
      end
      self
    end

    private

    # Encode the data markers into the HTML data
    def self.encode_data(html,frag_start,frag_end,select_start,select_end,src)
      dummy_prefix = MARKER_BLOCK_OUTPUT % [0,0,0,0,0,0,src]
      len_prefix = dummy_prefix.length
      prefix = MARKER_BLOCK_OUTPUT % [len_prefix, html.length + len_prefix,
      frag_start + len_prefix, frag_end + len_prefix,
      select_start + len_prefix, select_end + len_prefix, src]
      prefix + html
    end

    # Decode the given string to figure out the details of the HTML
    # that's on the string.
    #--
    # Try the extended format first, which has an explicit selection.
    # If that fails, try the version without a selection.
    #
    def self.decode_data(src)
      if (matches = MARKER_BLOCK_EX_RE.match(src))
        @prefix = matches[0]
        @version = matches[1]
        @html = src[matches[2].to_i ... matches[3].to_i]
        @fragment = src[matches[4].to_i ... matches[5].to_i]
        @selection = src[matches[6].to_i ... matches[7].to_i]
        @source = matches[8]
      elsif (matches = MARKER_BLOCK_RE.match(src))
        @prefix = matches[0]
        @version = matches[1]
        @html = src[matches[2].to_i ... matches[3].to_i]
        @fragment = src[matches[4].to_i ... matches[5].to_i]
        @source = matches[6]
        @selection = @fragment
      else
        raise Error, 'failed to match block markers'
      end
      @fragment
    end
  end
end
