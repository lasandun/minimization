require 'ffi'

module OpenCLMinimization extend FFI::Library

  ffi_lib "#{File.dirname(__FILE__)}/cl.so"

  attach_function 'opencl_minimize', [:int, :pointer, :pointer, :pointer, :int, :string, :string,
                                     :string, :pointer, :pointer, :int], :void

  class GodlSectionMinimizer
    attr_reader :x_minimum
    attr_reader :f_minimum

    def initialize(n, start_point, expected_point, end_point, f)
      @n              = n
      @start_point    = start_point
      @expected_point = expected_point
      @end_point      = end_point
      @f              = f
    end

    def minimize
      start_buffer    = FFI::Buffer.alloc_inout(:pointer, @n)
      expected_buffer = FFI::Buffer.alloc_inout(:pointer, @n)
      end_buffer      = FFI::Buffer.alloc_inout(:pointer, @n)
      x_buffer        = FFI::Buffer.alloc_inout(:pointer, @n)
      f_buffer        = FFI::Buffer.alloc_inout(:pointer, @n)

      start_buffer.write_array_of_float(@start_point)
      expected_buffer.write_array_of_float(@expected_point)
      end_buffer.write_array_of_float(@end_point)

      OpenCLMinimization::opencl_minimize(@n, start_buffer, expected_buffer, end_buffer, 0, @f, "", "", x_buffer, f_buffer, 0)

      @x_minimum = Array.new(@n)
      @f_minimum = Array.new(@n)
      @x_minimum = x_buffer.read_array_of_float(@n)
      @f_minimum = f_buffer.read_array_of_float(@n)
    end
    end

  class NewtonRampsonMinimizer
    attr_reader :x_minimum
    attr_reader :f_minimum

    def initialize(n, expected_point, f, fd, fdd)
      @n              = n
      @expected_point = expected_point
      @f              = f
      @fd             = fd
      @fdd            = fdd
    end

    def minimize
      expected_buffer = FFI::Buffer.alloc_inout(:pointer, @n)
      x_buffer        = FFI::Buffer.alloc_inout(:pointer, @n)
      f_buffer        = FFI::Buffer.alloc_inout(:pointer, @n)

      expected_buffer.write_array_of_float(@expected_point)

      OpenCLMinimization::opencl_minimize(@n, nil, expected_buffer, nil, 1, @f, @fd, @fdd, x_buffer, f_buffer, 0)

      @x_minimum = Array.new(@n)
      @f_minimum = Array.new(@n)
      @x_minimum = x_buffer.read_array_of_float(@n)
      @f_minimum = f_buffer.read_array_of_float(@n)
    end
  end

  class BisectionMinimizer < GodlSectionMinimizer
    def minimize
      start_buffer    = FFI::Buffer.alloc_inout(:pointer, @n)
      expected_buffer = FFI::Buffer.alloc_inout(:pointer, @n)
      end_buffer      = FFI::Buffer.alloc_inout(:pointer, @n)
      x_buffer        = FFI::Buffer.alloc_inout(:pointer, @n)
      f_buffer        = FFI::Buffer.alloc_inout(:pointer, @n)

      start_buffer.write_array_of_float(@start_point)
      expected_buffer.write_array_of_float(@expected_point)
      end_buffer.write_array_of_float(@end_point)

      OpenCLMinimization::opencl_minimize(@n, start_buffer, expected_buffer, end_buffer, 2, @f, "", "", x_buffer, f_buffer, 0)

      @x_minimum = Array.new(@n)
      @f_minimum = Array.new(@n)
      @x_minimum = x_buffer.read_array_of_float(@n)
      @f_minimum = f_buffer.read_array_of_float(@n)
    end
  end

  class BrentMinimizer
    attr_reader :x_minimum
    attr_reader :f_minimum

    def initialize(n, start_point, expected_point, end_point, f)
      @n              = n
      @start_point    = start_point
      @expected_point = expected_point
      @end_point      = end_point
      @f              = f
    end

    def minimize
      start_buffer    = FFI::Buffer.alloc_inout(:pointer, @n)
      expected_buffer = FFI::Buffer.alloc_inout(:pointer, @n)
      end_buffer      = FFI::Buffer.alloc_inout(:pointer, @n)
      x_buffer        = FFI::Buffer.alloc_inout(:pointer, @n)
      f_buffer        = FFI::Buffer.alloc_inout(:pointer, @n)

      start_buffer.write_array_of_float(@start_point)
      expected_buffer.write_array_of_float(@expected_point)
      end_buffer.write_array_of_float(@end_point)

      OpenCLMinimization::opencl_minimize(@n, start_buffer, expected_buffer, end_buffer, 3, @f, "", "", x_buffer, f_buffer, 0)

      @x_minimum = Array.new(@n)
      @f_minimum = Array.new(@n)
      @x_minimum = x_buffer.read_array_of_float(@n)
      @f_minimum = f_buffer.read_array_of_float(@n)
    end
  end


end

puts "golden section--------------------------"
n              = 3
start_point    = [1, 3, 5]
expected_point = [1.5, 3.5, 5.5]
end_point      = [3, 5, 7]
f              = "pow((x-2)*(x-4)*(x-6), 2)+1"
min = OpenCLMinimization::GodlSectionMinimizer.new(n, start_point, expected_point, end_point, f)
min.minimize
puts min.x_minimum.inspect
puts min.f_minimum.inspect




puts "bisection--------------------------"
n              = 3
start_point    = [1, 3, 5]
expected_point = [1.5, 3.5, 5.5]
end_point      = [3, 5, 7]
f              = "pow((x-2)*(x-4)*(x-6), 2)+1"
min = OpenCLMinimization::BisectionMinimizer.new(n, start_point, expected_point, end_point, f)
min.minimize
puts min.x_minimum.inspect
puts min.f_minimum.inspect




puts "newton rampson--------------------------"
n              = 3
expected_point = [1, 100, 1000]
f              = "(x-3)*(x-3)+5"
fd             = "2*(x-3)"
fdd            = "2"
min = OpenCLMinimization::NewtonRampsonMinimizer.new(n, expected_point, f, fd, fdd)
min.minimize
puts min.x_minimum.inspect
puts min.f_minimum.inspect




puts "brent------------------------------------"
n              = 3
f              = "(x-55)*(x-55)+5"
start_point    = [1, 3, 5]
expected_point = [33, 55, 77]
end_point      = [100, 300, 500]
min = OpenCLMinimization::BrentMinimizer.new(n, start_point, expected_point, end_point, f)
min.minimize
puts min.x_minimum.inspect
puts min.f_minimum.inspect
