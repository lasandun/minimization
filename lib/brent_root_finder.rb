module Minimization
  class BrentRootFinder
    EPSILON = 10e-6

    def brent(lo, hi, f)
      a  = lo
      fa = f.call(lo)
      b  = hi
      fb = f.call(hi)
      c  = a
      fc = fa
      d  = b - a
      e  = d

      t   = EPSILON # Absolute Accuracy
      eps = EPSILON # Relative Accuracy

      loop do
        if (fc.abs < fb.abs)
          a  = b
          b  = c
          c  = a
          fa = fb
          fb = fc
          fc = fa
        end

        tol = 2 * eps * b.abs + t
        m   = 0.5 * (c - b)

        if (m.abs <= tol or fb.abs < EPSILON)
          return b
        end
        if (e.abs < tol or fa.abs <= fb.abs)
          d = m
          e = d
        else 
          s = fb / fa
          if (a == c)
            p = 2 * m * s
            q = 1 - s
          else
            q = fa / fc
            r = fb / fc
            p = s * (2 * m * q * (q - r) - (b - a) * (r - 1))
            q = (q - 1) * (r - 1) * (s - 1)
          end
          if (p > 0)
            q = -q
          else 
            p = -p
          end
          s = e
          e = d
          if (p >= 1.5 * m * q - (tol * q).abs or p >= (0.5 * s * q).abs)
            d = m
            e = d
          else
            d = p / q
          end
        end
        a  = b
        fa = fb

        if (d.abs > tol)
          b += d
        elsif (m > 0)
          b += tol
        else
          b -= tol
        end
        fb = f.call(b)
        if ((fb > 0 and fc > 0) or (fb <= 0 and fc <= 0))
          c  = a
          fc = fa
          d  = b - a
          e  = d
        end
      end
    end
  end
end

root = Minimization::BrentRootFinder.new
func = proc{|x| (x-3)**2}
puts root.brent(0, 5, func)
