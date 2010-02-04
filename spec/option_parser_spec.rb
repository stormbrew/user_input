require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'lib/user_input/option_parser'

describe UserInput::OptionParser do
	IOptionParser = UserInput::OptionParser
	
	before :each do
		@opt = IOptionParser.new("testing")
		@opt.flag "a", "abba", "stuff goes here"
		@opt.flag "b", "boom", "this one goes boom" do raise "BOOM" end
		@opt.argument "c", "cool", "this one is awesome", "whatever"
		@opt.argument "d", "dumb", "this one is dumb. It wants nothing but an integer.", 5, Integer
		@opt.argument "e", "everything", "this one's really clever, it's always 'everything'", "what?" do "everything" end
	end
	
	it "Should have defined the right methods" do
		[:abba?, :boom?, :cool, :dumb, :everything].each {|i|
			@opt.respond_to?(i).should be_true
		}
	end
	
	it "Should set the correct defaults" do
		@opt.abba?.should be_false
		@opt.boom?.should be_false
		@opt.cool.should == "whatever"
		@opt.dumb.should == 5
		@opt.everything.should == "what?"
	end
	
	it "Should return itself from both parse and parse!" do
		@opt.parse(["-a"]).should == @opt
		@opt.parse!(["-a"]).should == @opt
	end

	it "Should parse a simple short flag" do
		@opt.parse(["-a"])
		@opt.abba?.should be_true
	end
	
	it "Should parse a simple long flag" do
		@opt.parse(["--abba"])
		@opt.abba?.should be_true
	end
	
	it "Should raise an error if we try to set the exploding flag" do
		proc { @opt.parse(["-b"]) }.should raise_error("BOOM")
	end
	
	it "Should raise if an argument isn't supplied to a normal argument" do
		proc { @opt.parse(["-c"]) }.should raise_error(ArgumentError)
	end
	
	it "Should parse a simple argument with properly specified" do
		@opt.parse(["-c", "stuff"])
		@opt.cool.should == "stuff"
	end
	
	it "Should parse a simple argument in its long form properly specified" do
		@opt.parse(["--cool", "stuff"])
		@opt.cool.should == "stuff"
	end

	it "should parse a flag and an argument separately" do
		@opt.parse(["-a", "-c", "stuff"])
		@opt.abba?.should be_true
		@opt.cool.should == "stuff"
	end
	
	it "Should validate input using from_user_input" do
		proc { @opt.parse(["-d", "whatever"]) }.should raise_error(ArgumentError)
		@opt.dumb.should == 5
		@opt.parse(["-d", "99"])
		@opt.dumb.should == 99
	end
	
	it "Should validate input using a proc object" do
		@opt.parse(["-e", "stufffff"])
		@opt.everything.should == "everything"
	end
	
	it "should parse correctly if you specify multiple arguments in a group" do
		@opt.parse(["-acd", "what", "1"])
		@opt.abba?.should be_true
		@opt.cool.should == "what"
		@opt.dumb.should == 1
	end

	it "should parse destructively if you use parse!" do
		arr = ["-a"]
		@opt.parse!(arr)
		arr.should == []
	end
	
	it "should stop parsing on finding a non-flag word unexpectedly and return the remainder" do
		arr = ["-a", "boom", "whatever"]
		@opt.parse!(arr)
		arr.should == ["boom", "whatever"]
	end
end