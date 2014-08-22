require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
describe Minimization::Unidimensional, "subclass" do 

  before(:all) do
    @n  = 4
    @func   = lambda {|x| ((x - 1) * (x - 2) * (x - 3) * (x - 4)).abs }
    @lower_limits = [-1000, 1.5, 2.5, 3.5]
    @upper_limits = [ 1.5, 2.5, 3.5, 1000]
    @x_results = [1, 2, 3, 4]
    @f_results = [0, 0, 0, 0]
  end
  
  describe Minimization::NewtonRaphson  do
    before do
      @n1 = 2
      f = proc{ |x| ((x - 1) * (x - 2)) ** 2 }
      fd = proc{ |x| 2 * (x - 1) * (x - 2) * (2 * x - 3) }
      fdd = proc{ |x| 2 * (6 * x * x - 18 * x + 13)}
      lower_limits = [-1000, 1.5]
      upper_limits = [ 1.5, 1000]
      @x_results1 = [1, 2]
      @f_results1 = [0, 0]
      @min = Minimization::NewtonRaphson.new(lower_limits, upper_limits, f, fd, fdd)
      @min.iterate
    end
    it "#x_minimum be close to expected" do 
      0.upto(@n1 - 1) do |i|
        @min.x_minimum[i].should be_within(@min.epsilon).of(@x_results1[i])
      end
    end
    it "#f_minimum ( f(x)) be close to expected" do 
      0.upto(@n1 - 1) do |i|
        @min.f_minimum[i].should be_within(@min.epsilon).of(@f_results1[i])
      end
    end
    context "#log" do
      it {should be_instance_of Array}
      it {should respond_to :to_table}
    end
  end
  
  describe Minimization::GoldenSection  do
    before do
      @min = Minimization::GoldenSection.minimize(@lower_limits, @upper_limits, &@func)
    end
    it "#x_minimum be close to expected" do 
      0.upto(@n - 1) do |i|
        @min.x_minimum[i].should be_within(@min.epsilon).of(@x_results[i])
      end
    end
    it "#f_minimum ( f(x)) be close to expected" do 
      0.upto(@n - 1) do |i|
        @min.f_minimum[i].should be_within(@min.epsilon).of(@f_results[i])
      end
    end
    context "#log" do
      subject {@min.log}
      it {should be_instance_of Array}
      it {should respond_to :to_table}
    end
  end

  describe Minimization::Brent  do
    before do
      @min = Minimization::Brent.minimize(@lower_limits, @upper_limits, &@func)
    end
    it "should x be correct" do 
      0.upto(@n - 1) do |i|
        @min.x_minimum[i].should be_within(@min.epsilon).of(@x_results[i])
      end
    end
    it "should f(x) be correct" do 
      0.upto(@n - 1) do |i|
        @min.f_minimum[i].should be_within(@min.epsilon).of(@f_results[i])
      end
    end
    context "#log" do
      subject {@min.log}
      it {should be_instance_of Array}
      it {should respond_to :to_table}
    end
  end
end
