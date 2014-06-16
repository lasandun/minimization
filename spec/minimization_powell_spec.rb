require "./../lib/powell.rb"

describe Minimization::PowellMinimizer do
  before do
    @n           = 3
    @limit       = 100
    @epsilon     = 1e-5
    @p           = Array.new(@n)
    @start_point = Array.new(@n)

    0.upto(@n - 1) do |i|
      @p[i] = rand(@limit)
    end

    0.upto(@n - 1) do |i|
      @start_point[i] = rand(@limit)
    end

    # example 1
    f = proc{ |x| (x[0] - @p[0])**2 + (x[1] - @p[1])**2 + (x[2] - @p[2])**2 }
    @min1 = Minimization::PowellMinimizer.new(f, @start_point, [-@limit, -@limit, -@limit], [@limit, @limit, @limit])
    while(@min1.converging)
      @min1.minimize
    end

  end

  it "#x_minimum be close to expected in example 1" do 
    0.upto(@n - 1) do |i|
      @min1.x_minimum[i].should be_within(@epsilon).of(@p[i])
    end
  end

  it "#f_minimum be close to expected in example 1" do 
    @min1.f_minimum.should be_within(@epsilon).of(0)
  end

end
