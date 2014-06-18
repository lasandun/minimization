require "#{File.dirname(__FILE__)}/point_value_pair.rb"
require "#{File.dirname(__FILE__)}/minimization.rb"

module Minimization

  class NonLinearConjugateGradientMinimizer

    MAX_EVALUATIONS_DEFAULT = 100000
    MAX_ITERATIONS_DEFAULT  = 100000
    
    def initialize(f, fd, start_point, beta_formula)
      @f = f
      @fd = fd
      @start_point = start_point

      @max_iterations = MAX_ITERATIONS_DEFAULT
      @max_evaluations = MAX_EVALUATIONS_DEFAULT
      @iterations = 0
      @update_formula = beta_formula
    end

    def f(x)
      @iterations += 1
      raise "max evaluation limit exeeded: #{@max_iterations}" if @iterations > @max_iterations
      return @f.call(x)
    end

    def gradient(x)
      return @fd.call(x)
    end

    def set_initial_step(initial_step)
      if (initial_step <= 0) 
        @initial_step = 1.0
      else
        @initial_step = initial_step 
      end
    end

    def find_upper_bound(a, h)
      ya = value(a)
      yb = ya
      step = h
      # check step value for float max value exceeds
      while step < Float::MAX
        b  = a + step
        yB = value(b)
        if (ya * yB <= 0)
          return b
        end
        step *= [2, ya / yb].max
      end
      # raise error if bracketing failed
      raise "Unable to bracket minimum in line search."
    end

    def precondition(point, r)

    end

    def converged(previous, current)

    end

    def solve(a, b, c)

    end

    def value(x)
      # current point in the search direction
      shifted_point = @point.clone()
      0.upto(shifted_point.length - 1) do |i|
        shifted_point[i] += x * @search_direction[i];
      end

      # gradient of the objective function
      gradient = computeObjectiveGradient(shiftedPoint)

      # dot product with the search direction
      dot_product = 0
      0.upto(gradient.length - 1) do |i|
        dot_product += gradient[i] * @search_direction[i]
      end

      return dot_product
    end
    
    def minimize
      @point = @start_point.clone
      n = @point.length
      r = gradient(@point)
      # if (goal == GoalType.MINIMIZE) {
      0.upto(n - 1) do |i|
        r[i] = -r[i]
      end

      # Initial search direction.
      steepest_descent = precondition(@point, r)
      search_direction = steepest_descent.clone

      delta = 0
      0.upto(n - 1) do |i|
          delta += r[i] * @search_direction[i]
      end

      current = nil

      loop do
        @iterations += 1
        objective = f(@point)
        previous = current
        current = Minimization::PointValuePair.new(@point, objective)
        if (previous != nil and converged(previous, current))
          # We have found an minimum
          return current
        end

        uB = find_upper_bound(0, @initial_step)
        step = solve(0, uB, 1e-15)

        # Validate new point
        0.upto(@point.length - 1) do |i|
          point[i] += step * @search_direction[i]
        end

        r = gradient(point)
        0.upto(n - 1) do |i|
          r[i] = -r[i]
        end

        # Compute beta
        delta_old = delta
        new_steepest_descent = precondition(point, r)
        delta = 0
        0.upto(n - 1) do |i|
          delta += r[i] * new_steepest_descent[i]
        end

        if (@update_formula == :fletcher_reeves)
          beta = delta / delta_old
        elsif(@update_formula == :polak_ribiere)
          deltaMid = 0
          0.upto(r.length - 1) do |i|
            deltaMid += r[i] * steepest_descent[i]
          end
          beta = (delta - deltaMid) / delta_old
        else
          raise "Unknown beta formula type"
        end
        steepest_descent = new_steepest_descent

        # Compute conjugate search direction
        if (@iterations % n == 0 || beta < 0)
          # Break conjugation: reset search direction
          @search_direction = steepest_descent.clone
        else
          # Compute new conjugate search direction
          0.upto(n - 1) do |i|
            @search_direction[i] = steepest_descent[i] + beta * @search_direction[i]
          end
        end

      end

    end

  end

end
