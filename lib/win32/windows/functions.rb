require 'ffi'

module Windows
  module Functions
    extend FFI::Library

    typedef :uintptr_t, :hglobal
    typedef :uintptr_t, :hwnd
    typedef :uintptr_t, :handle
    typedef :uintptr_t, :hdrop

    ffi_lib FFI::Library::LIBC

    attach_function :memcpy, [:pointer, :string, :size_t], :pointer

    ffi_lib :kernel32

    attach_function :GlobalAlloc, [:uint, :size_t], :hglobal
    attach_function :GlobalFree, [:hglobal], :hglobal
    attach_function :GlobalLock, [:hglobal], :pointer
    attach_function :GlobalSize, [:hglobal], :size_t

    ffi_lib :user32

    attach_function :CloseClipboard, [], :bool
    attach_function :CountClipboardFormats, [], :int
    attach_function :EmptyClipboard, [], :bool
    attach_function :EnumClipboardFormats, [:uint], :uint
    attach_function :GetClipboardData, [:uint], :handle
    attach_function :GetClipboardFormatNameA, [:uint, :pointer, :int], :int
    attach_function :IsClipboardFormatAvailable, [:uint], :bool
    attach_function :OpenClipboard, [:hwnd], :bool
    attach_function :RegisterClipboardFormatA, [:string], :uint
    attach_function :SetClipboardData, [:uint, :handle], :handle

    ffi_lib :shell32

    attach_function :DragQueryFileA, [:hdrop, :uint, :pointer, :uint], :uint
  end
end

