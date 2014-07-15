require 'ffi'

module OpenCLMinimization extend FFI::Library
  ffi_lib './cl.so'
  attach_function 'util_integrate', [:int, :pointer, :pointer, :pointer, :int, :string, :string, :string, :pointer,
  :pointer], :void

  class OpenCLMinimizer
    attr_reader :x_minimum
    attr_reader :f_minimum

    def initialize(n, start_point, expected_point, end_point, f, fd, fdd)
      @n              = n
      @start_point    = start_point
      @expected_point = expected_point
      @end_point      = end_point
      @f              = f
      @fd             = fd
      @fdd            = fdd
    end

    def minimize(method)
      case(method)
        when :golden_section
          minimize_internal(0)
        when :newton_raphson
          minimize_internal(1)
        when :bisection
          minimize_internal(2)
        when :brent
          minimize_internal(3)
        else
          raise "unsupported minimizing method"
      end
    end

    private
    def minimize_internal(method)
      start_buffer    = FFI::Buffer.alloc_inout(:pointer, @n)
      expected_buffer = FFI::Buffer.alloc_inout(:pointer, @n)
      end_buffer      = FFI::Buffer.alloc_inout(:pointer, @n)
      x_buffer        = FFI::Buffer.alloc_inout(:pointer, @n)
      f_buffer        = FFI::Buffer.alloc_inout(:pointer, @n)

      start_buffer.write_array_of_float(@start_point)
      expected_buffer.write_array_of_float(@expected_point)
      end_buffer.write_array_of_float(@end_point)

      OpenCLMinimization::util_integrate(@n, start_buffer, expected_buffer, end_buffer, method, @f, @fd, @fdd, x_buffer, f_buffer)

      @x_minimum = Array.new(@n)
      @f_minimum = Array.new(@n)
      @x_minimum = x_buffer.read_array_of_float(@n)
      @f_minimum = f_buffer.read_array_of_float(@n)
    end

  end

end

n              = 3
start_point    = [1, 3, 5]
expected_point = [0.5, 3.5, 5.5]
end_point      = [3, 5, 7]
method         = :bisection
f              = "pow((x-2)*(x-4)*(x-6), 2)+1"
fd             = "1"
fdd            = "1"

min = OpenCLMinimization::OpenCLMinimizer.new(n, start_point, expected_point, end_point, f, fd, fdd)
min.minimize(method)
puts min.x_minimum.inspect
puts min.f_minimum.inspect
