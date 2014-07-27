require './../lib/opencl/opencl_minimization.rb'

describe OpenCLMinimization::GoldenSectionMinimizer do 
  before :all do
    @n              = 3
    @start_point    = [1, 3, 5]
    @expected_point = [1.5, 3.5, 5.5]
    @end_point      = [3, 5, 7]
    @f              = "pow((x-2)*(x-4)*(x-6), 2)+1"
    @min = OpenCLMinimization::GoldenSectionMinimizer.new(@n, @start_point, @expected_point, @end_point, @f)
    @min.minimize

    @x              = [2, 4, 6]
    @f              = [1, 1, 1]
  end
  it "#x_minimum be close to expected" do 
    0.upto(@n - 1) do |i|
      expect(@min.x_minimum[i]).to be_within(@min.epsilon).of(@x[i])
    end
  end
  it "#f_minimum ( f(x)) be close to expected" do 
    0.upto(@n - 1) do |i|
      expect(@min.f_minimum[i]).to be_within(@min.epsilon).of(@f[i])
    end
  end
end

describe OpenCLMinimization::BisectionMinimizer do 
  before :all do
    @n              = 3
    @start_point    = [1, 3, 5]
    @expected_point = [1.5, 3.5, 5.5]
    @end_point      = [3, 5, 7]
    @f              = "pow((x-2)*(x-4)*(x-6), 2)+1"
    @min = OpenCLMinimization::BisectionMinimizer.new(@n, @start_point, @expected_point, @end_point, @f)
    @min.minimize

    @x              = [2, 4, 6]
    @f              = [1, 1, 1]
  end
  it "#x_minimum be close to expected" do 
    0.upto(@n - 1) do |i|
      expect(@min.x_minimum[i]).to be_within(@min.epsilon).of(@x[i])
    end
  end
  it "#f_minimum ( f(x)) be close to expected" do 
    0.upto(@n - 1) do |i|
      expect(@min.f_minimum[i]).to be_within(@min.epsilon).of(@f[i])
    end
  end
end

describe OpenCLMinimization::BrentMinimizer do 
  before :all do
    @n              = 3
    @start_point    = [1, 3, 5]
    @expected_point = [1.5, 3.5, 5.5]
    @end_point      = [3, 5, 7]
    @f              = "pow((x-2)*(x-4)*(x-6), 2)+1"
    @min = OpenCLMinimization::BrentMinimizer.new(@n, @start_point, @expected_point, @end_point, @f)
    @min.minimize

    @x              = [2, 4, 6]
    @f              = [1, 1, 1]
  end
  it "#x_minimum be close to expected" do 
    0.upto(@n - 1) do |i|
      expect(@min.x_minimum[i]).to be_within(@min.epsilon).of(@x[i])
    end
  end
  it "#f_minimum ( f(x)) be close to expected" do 
    0.upto(@n - 1) do |i|
      expect(@min.f_minimum[i]).to be_within(@min.epsilon).of(@f[i])
    end
  end
end


describe OpenCLMinimization::NewtonRampsonMinimizer do 
  before :all do
    @n              = 3
    @expected_point = [1, 100, 1000]
    @f              = "(x-3)*(x-3)+5"
    @fd             = "2*(x-3)"
    @fdd            = "2"
    @min = OpenCLMinimization::NewtonRampsonMinimizer.new(@n, @expected_point, @f, @fd, @fdd)
    @min.minimize

    @x              = [3, 3, 3]
    @f              = [5, 5, 5]
  end
  it "#x_minimum be close to expected" do 
    0.upto(@n - 1) do |i|
      expect(@min.x_minimum[i]).to be_within(@min.epsilon).of(@x[i])
    end
  end
  it "#f_minimum ( f(x)) be close to expected" do 
    0.upto(@n - 1) do |i|
      expect(@min.f_minimum[i]).to be_within(@min.epsilon).of(@f[i])
    end
  end

end
