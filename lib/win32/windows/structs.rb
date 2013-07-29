require 'ffi'

module Windows
  module Structs
    extend FFI::Library

    typedef :uchar, :byte
    typedef :ulong, :dword
    typedef :ushort, :word

    class RGBQUAD < FFI::Struct
      layout(
        :rgbBlue, :byte,
        :rgbGreen, :byte,
        :rgbRed, :byte,
        :rgbReserved, :byte,
      )
    end

    class BITMAPINFOHEADER < FFI::Struct
      layout(
        :biSize, :dword,
        :biWidth, :long,
        :biHeight, :long,
        :biPlanes, :word,
        :biBitCount, :word,
        :biCompression, :dword,
        :biSizeImage, :dword,
        :biXPelsPerMeter, :long,
        :biYPelsPerMeter, :long,
        :biClrUsed, :dword,
        :biClrImportant, :dword
      )
    end

    class BITMAPINFO < FFI::Struct
      layout(
        :bmiHeader, BITMAPINFOHEADER,
        :bmiColor, [RGBQUAD, 1]
      )
    end
  end
end
