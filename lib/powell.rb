require "./point_value_pair.rb"
require "./minimization.rb"

module Minimization
  class ConjugateDirectionMinimizer
    attr_accessor :max_iterations
    attr_accessor :max_evaluations
    attr_accessor :max_brent_iterations
    attr_accessor :x_minimum
    attr_accessor :f_minimum
    attr_reader   :converging

    Max_Iterations_Default      = 100
    Max_Evaluations_Default     = 100
    MAX_BRENT_ITERATION_DEFAULT = 10   # give a suitable value

    def initialize(f, initial_guess, lower_bound, upper_bound)
      @iterations           = 0
      @max_iterations       = Max_Iterations_Default
      @evaluations          = 0
      @max_evaluations      = Max_Evaluations_Default
      @max_brent_iterations = MAX_BRENT_ITERATION_DEFAULT
      @converging           = true

      @f                    = f
      @start                = initial_guess
      @lower_bound          = lower_bound
      @upper_bound          = upper_bound

      @min_coordinate_val   = lower_bound.min
      @max_coordinate_val   = upper_bound.max

      check_parameters
    end

    def f(x)
      raise "Too many evaluations : #{@max_evaluations}" if @evaluations > @max_evaluations
      @f.call(x)
    end
    
    def check_parameters
      if (!@start.nil?)
        dim = @start.length
        if (!@lower_bound.nil?)
          raise "dimension mismatching #{@lower_bound.length} and #{dim}" if @lower_bound.length != dim
          0.upto(dim - 1) do |i|
            v = @start[i]
            lo = @lower_bound[i]
            raise "start point is lower than lower bound" if v < lo
          end
        end
        if (!@upper_bound.nil?)
          raise "dimension mismatching #{@upper_bound.length} and #{dim}" if @upper_bound.length != dim
          0.upto(dim - 1) do |i|
            v = @start[i]
            hi = @upper_bound[i]
            raise "start point is higher than the upper bound" if v > hi
          end
        end

        if (@lower_bound.nil?)
          @lower_bound = Array.new(dim)
          0.upto(dim - 1) do |i|
            @lower_bound[i] = Float::INFINITY # eventually this will occur an error
          end
        end
        if (@upper_bound.nil?)
          @upper_bound = Array.new(dim)
          0.upto(dim - 1) do |i|
            @upper_bound[i] = -Float::INFINITY # eventually this will occur an error
          end
        end
      end
    end

    def brent_search(point, direction)
      n = point.length
      func = proc{ |alpha|
        x = Array.new(n)
        0.upto(n - 1) do |i|
          x[i] = point[i] + alpha * direction[i]
        end
        f(x)
      }

      line_minimizer = Minimization::Brent.new(@min_coordinate_val, @max_coordinate_val, func)
      0.upto(@max_brent_iterations) do
        line_minimizer.iterate
      end
      return {:alpha_min => line_minimizer.x_minimum, :f_val => line_minimizer.f_minimum}
    end

  end

  class PowellMinimizer < ConjugateDirectionMinimizer

    attr_accessor :relative_threshold
    attr_accessor :absolute_threshold

    RELATIVE_THRESHOLD_DEFAULT = 0.1
    ABSOLUTE_THRESHOLD_DEFAULT =0.1

    def initialize(f, initial_guess, lower_bound, upper_bound)
      super(f, initial_guess.clone, lower_bound, upper_bound)
      @relative_threshold = RELATIVE_THRESHOLD_DEFAULT
      @absolute_threshold = ABSOLUTE_THRESHOLD_DEFAULT
    end

    def new_point_and_direction(point, direction, minimum)
      n         = point.length
      new_point = Array.new(n)
      new_dir   = Array.new(n)
      0.upto(n - 1) do |i|
        new_dir[i]   = direction[i] * minimum
        new_point[i] = point[i] + new_dir[i]
      end
      return {:point => new_point, :dir => new_dir}
    end

    def minimize
      @iterations += 1

      if(@iterations <= 1)
        guess = @start
        @n     = guess.length
        @direc = Array.new(@n) { Array.new(@n) {0} } # initialize all to 0
        0.upto(@n - 1) do |i|
          @direc[i][i] = 1
        end

        @x     = guess
        @f_val = f(@x)
        @x1    = @x.clone
      end

      fx        = @f_val
      fx2       = 0
      delta     = 0
      big_ind   = 0
      alpha_min = 0

      0.upto(@n - 1) do |i|
        direction = @direc[i].clone
        fx2       = @f_val
        minimum   = brent_search(@x, direction)
        @f_val     = minimum[:f_val]
        alpha_min = minimum[:alpha_min]
        new_pnd   = new_point_and_direction(@x, direction, alpha_min)
        new_point = new_pnd[:point]
        new_dir   = new_pnd[:dir]
        @x         = new_point

        if ((fx2 - @f_val) > delta) 
          delta   = fx2 - @f_val
          big_ind = i
        end
      end

      # convergence check
      @converging = !(2 * (fx - @f_val) <= (@relative_threshold * (fx.abs + @f_val.abs) + @absolute_threshold))

      # storing results
      if((@f_val < fx))
        @x_minimum = @x
        @f_minimum = @f_val
      else
        @x_minimum = @x1
        @f_minimum = fx
      end

      direction  = Array.new(@n)
      x2         = Array.new(@n)
      0.upto(@n -1) do |i|
        direction[i]  = @x[i] - @x1[i]
        x2[i]         = 2 * @x[i] - @x1[i]
      end

      @x1  = @x.clone
      fx2 = f(x2)

      if (fx > fx2)
        t    = 2 * (fx + fx2 - 2 * @f_val)
        temp = fx - @f_val - delta
        t   *= temp * temp
        temp = fx - fx2
        t   -= delta * temp * temp

        if (t < 0.0)
          minimum   = brent_search(@x, direction)
          @f_val     = minimum[:f_val]
          alpha_min = minimum[:alpha_min]
          new_pnd   = new_point_and_direction(@x, direction, alpha_min)
          new_point = new_pnd[:point]
          new_dir   = new_pnd[:dir]
          @x         = new_point

          last_ind        = @n - 1
          @direc[big_ind]  = @direc[last_ind]
          @direc[last_ind] = new_dir
        end
      end
    end

  end
end

f = proc{ |x| (x[0] - 1)**2 + (2*x[1] - 5)**2 + (x[2]-3.3)**2}
x = Minimization::PowellMinimizer.new(f, [1, 2, 3], [0, 0, 0], [5, 5, 5])

while(x.converging)
  x.minimize
  puts "#{x.x_minimum}     #{x.f_minimum}"
end



