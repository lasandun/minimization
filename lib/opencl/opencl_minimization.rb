require 'ffi'

module OpenCLMinimization extend FFI::Library
  ffi_lib './cl.so'
  attach_function 'util_integrate', [:int, :pointer, :pointer, :pointer, :int, :string, :string, :string, :pointer,
  :pointer], :void
end

