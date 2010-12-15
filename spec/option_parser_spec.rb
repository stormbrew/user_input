require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'lib/user_input/option_parser'

describe UserInput::OptionParser do
	IOptionParser = UserInput::OptionParser
	
	it "Should optionally take an argument for program prefix, setting it to $0 if none set" do
		IOptionParser.new().program_prefix.should == $0
		IOptionParser.new("blah").program_prefix.should == "blah"
	end
	
	it "Should let you set the program prefix after initialization" do
		opt = IOptionParser.new
		opt.program_prefix.should == $0
		opt.program_prefix = "blah"
		opt.program_prefix.should == "blah"
	end
	
	it "Should generate a default banner if none specified" do
		IOptionParser.new().banner.should be_kind_of(String)
	end
	it "Should let you set the banner" do
		opt = IOptionParser.new
		opt.banner = "blah"
		opt.banner.should == "blah"
	end
	
	it "Should yield the object for use if a block is given to the constructor" do
		IOptionParser.new("boom") {|p|
			p.should be_kind_of(IOptionParser)
			p.program_prefix.should == "boom"
		}
	end
	
	it "Should not allow multicharacter short options or single character long options" do
		IOptionParser.new {|p|
			proc { p.flag "boom", "boom", "what?" }.should raise_error(ArgumentError)
			proc { p.flag "a", "a", "what?" }.should raise_error(ArgumentError)
		}
	end
	
	before :each do
		@opt = IOptionParser.new("testing")
		@opt.flag "a", "abba", "stuff goes here"
		@opt.flag "b", "boom", "this one goes boom" do raise "BOOM" end
		@opt.argument "c", "cool", "this one is awesome", "whatever"
		@opt.gap
		@opt.argument "d", "dumb", "this one is dumb. It wants nothing but an integer.", 5, Integer
		@opt.argument "e", "everything", "this one's really clever, it's always 'everything'", "what?" do "everything" end
		@opt.argument "f", "fugged-aboudit", "this one has a hyphen, which makes it scary", "stuff"
	end
	
	it "Should have defined the right methods" do
		[:abba?, :boom?, :cool, :dumb, :everything, :fugged_aboudit].each {|i|
			@opt.respond_to?(i).should be_true
		}
	end
	
	it "Should set the correct defaults" do
		@opt.abba?.should be_false
		@opt.boom?.should be_false
		@opt.cool.should == "whatever"
		@opt.dumb.should == 5
		@opt.everything.should == "what?"
		@opt.fugged_aboudit.should == "stuff"
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

	it "Should deal with a hyphen in the command line argument" do
		@opt.parse(["--fugged-aboudit", "boom"])
		@opt.fugged_aboudit.should == "boom"
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
	
	it "Should raise an error if you supply a flag or argument it doesn't understand" do
		proc { @opt.parse(["-z"]) }.should raise_error(ArgumentError)
		proc { @opt.parse(["--zoom"]) }.should raise_error(ArgumentError)
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
	
	it "should stop parsing on finding --, but should still consume it" do
		arr = ["-a", "--", "whatever"]
		@opt.parse!(arr)
		arr.should == ["whatever"]
	end
	
	it "should save unknown barewords if you tell it to, and should continue parsing" do
		@opt.save_unknown!
		
		arr = ["-a", "boom", "-c", "blorp", "blah"]
		@opt.parse!(arr)
		arr.should == []
		@opt.saved.should == ["boom", "blah"]

		@opt.abba?.should be_true
		@opt.cool.should == "blorp"
	end
	
	it "should return a string from to_s" do
		# Possibly this spec should include an example to compare against, but that seems too rigid.
		@opt.to_s.should be_kind_of(String)
	end
end