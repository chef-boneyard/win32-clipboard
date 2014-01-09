require 'ffi'

module Windows
  module Functions
    extend FFI::Library

    typedef :uintptr_t, :hglobal
    typedef :uintptr_t, :hwnd
    typedef :uintptr_t, :handle
    typedef :uintptr_t, :hmenu
    typedef :uintptr_t, :hdrop
    typedef :uintptr_t, :hinstance
    typedef :ulong, :dword

    callback :wnd_proc, [:hwnd, :uint, :long, :long], :long

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
    attach_function :CreateWindowEx, :CreateWindowExA, [:dword, :string, :string, :dword, :int, :int, :int, :int, :hwnd, :hmenu, :hinstance, :pointer], :hwnd
    attach_function :DefWindowProc, :DefWindowProcA, [:hwnd, :uint, :uint, :uint], :long
    attach_function :DispatchMessage, :DispatchMessageA, [:pointer], :uint
    attach_function :EmptyClipboard, [], :bool
    attach_function :EnumClipboardFormats, [:uint], :uint
    attach_function :GetClipboardData, [:uint], :handle
    attach_function :GetClipboardFormatName, :GetClipboardFormatNameA, [:uint, :pointer, :int], :int
    attach_function :GetWindowLongPtr, :GetWindowLongPtrA, [:hwnd, :int], :long
    attach_function :IsClipboardFormatAvailable, [:uint], :bool
    attach_function :OpenClipboard, [:hwnd], :bool
    attach_function :PeekMessage, :PeekMessageA, [:pointer, :hwnd, :uint, :uint, :uint], :bool
    attach_function :PostMessage, :PostMessageA, [:hwnd, :uint, :uintptr_t, :uintptr_t], :bool
    attach_function :RegisterClipboardFormat, :RegisterClipboardFormatA, [:string], :uint
    attach_function :SetClipboardData, [:uint, :handle], :handle
    attach_function :SetClipboardViewer, [:hwnd], :hwnd
    attach_function :SetWindowLongPtr, :SetWindowLongPtrA, [:hwnd, :int, :uintptr_t], :long
    attach_function :TranslateMessage, [:pointer], :bool

    ffi_lib :shell32

    attach_function :DragQueryFileA, [:hdrop, :uint, :pointer, :uint], :uint

    ffi_lib :gdi32

    attach_function :GetEnhMetaFileBits, [:handle, :uint, :pointer], :uint
  end
end

