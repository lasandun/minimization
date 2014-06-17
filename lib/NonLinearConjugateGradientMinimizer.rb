class NonLinearConjugateGradientMinimizer
  
  def initialize()

  end

  def set_initial_step(initial_step)
    if (initial_step <= 0) 
      self -> initial_step = 1.0
    else
      self -> initial_step = initial_step 
    end
  end

  def find_upper_bound(a, h)
    ya = f(a)
    yb = ya
    step = h
    loop do
      # check step value for float max value exceeds
      b  = a + step
      yB = f(b)
      if (ya * yB <= 0)
        return b
      end
      step *= [2, ya / yb].max
    end
    #raise "Unable to bracket optimum in line search."
  end

  

end
