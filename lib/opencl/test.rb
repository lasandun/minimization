require 'ffi'
require './opencl_minimization.rb'

n               = 3
start_buffer    = FFI::Buffer.alloc_inout(:pointer, n)
expected_buffer = FFI::Buffer.alloc_inout(:pointer, n)
end_buffer      = FFI::Buffer.alloc_inout(:pointer, n)
method          = 2
f               = "pow((x-2)*(x-4)*(x-6), 2)+1"
fd              = "1"
fdd             = "1"
x_buffer        = FFI::Buffer.alloc_inout(:pointer, n)
f_buffer        = FFI::Buffer.alloc_inout(:pointer, n)

start_point    = [1, 3, 5]
expected_point = [0.5, 3.5, 5.5]
end_point      = [3, 5, 7]

start_buffer.write_array_of_float(start_point)
expected_buffer.write_array_of_float(expected_point)
end_buffer.write_array_of_float(end_point)
x_minimum      = Array.new(n)
f_minimum      = Array.new(n)

OpenCLMinimization::util_integrate(n, start_buffer, expected_buffer, end_buffer, method, f, fd, fdd, x_buffer, f_buffer)

x_minimum = x_buffer.read_array_of_float(n)
f_minimum = f_buffer.read_array_of_float(n)

puts x_minimum.inspect
puts f_minimum.inspect
