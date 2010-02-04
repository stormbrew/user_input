require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'lib/user_input'
require 'ipaddr'
require 'date'
require 'set'

describe "UserInput" do
	describe String do
		it "Should accept anything that can have to_s called on the class method" do
			String.from_user_input("OMGWTFBBQ").should == "OMGWTFBBQ"
			String.from_user_input(1).should == "1"
		end
		it "Should accept only equal strings (or things that can be to_s'd to an equal string) on the instance method" do
			"OMGWTFBBQ".from_user_input("OMGWTFBBQ").should == "OMGWTFBBQ"
			"OMGWTFBBQ".from_user_input("wat").should be_nil
			"1".from_user_input(1).should == "1"
		end
	end
	
	describe Boolean do
		it "Should accept true/false as boolean" do
			Boolean.from_user_input(true).should == true
			Boolean.from_user_input(false).should == false
		end
		it "Should accept various strings (true, false, on, off, y, n, enabled, disabled) as boolean values" do
			Boolean.from_user_input("true").should == true
			Boolean.from_user_input("on").should == true
			Boolean.from_user_input("y").should == true
			Boolean.from_user_input("enabled").should == true
			
			Boolean.from_user_input("false").should == false
			Boolean.from_user_input("off").should == false
			Boolean.from_user_input("n").should == false
			Boolean.from_user_input("disabled").should == false
		end
		it "Should generally not accept anything else as a boolean value" do
			Boolean.from_user_input(12321).should be_nil
			Boolean.from_user_input("fkjdjaslfs").should be_nil
		end
	end
	
	describe TrueClass do
		it "Should accept true as itself" do
			true.from_user_input(true).should == true
		end
		it "Should accept various strings (true, on, y, enabled) as true" do
			true.from_user_input("true").should == true
			true.from_user_input("on").should == true
			true.from_user_input("y").should == true
			true.from_user_input("enabled").should == true
		end
		it "Should generally not accept anything else as true" do
			true.from_user_input(3423).should be_nil
			true.from_user_input("fkjdjaslfs").should be_nil
			true.from_user_input(false).should be_nil
		end
	end
	
	describe FalseClass do
		it "Should accept false as itself" do
			false.from_user_input(false).should == false
		end
		it "Should accept various strings (false, off, n, disabled) as false" do
			false.from_user_input("false").should == false
			false.from_user_input("off").should == false
			false.from_user_input("n").should == false
			false.from_user_input("disabled").should == false
		end
		it "Should generally not accept anything else as false" do
			false.from_user_input(3423).should be_nil
			false.from_user_input("fkjdjaslfs").should be_nil
			false.from_user_input(true).should be_nil
		end
	end
	
	describe Date do
		it "Should accept a Date object as a date object" do
			Date.parse("January 20th, 2004").should_not be_nil
			Date.from_user_input(Date.parse("January 20th, 2004")).should == Date.parse("January 20th, 2004")
		end
		it "Should accept a string that Date.parse would accept as a date object" do
			Date.from_user_input("January 20th, 2004").should == Date.parse("January 20th, 2004")
		end
		it "Should not accept other strings as date objects." do
			Date.from_user_input("dfjskjfdsf").should be_nil
		end
	end
	
	describe Integer do
		it "Should take an integer object as an integer" do
			Integer.from_user_input(1).should == 1
		end
		it "Should take a string with an acceptable format (including leading and trailing whitespace) as an integer object" do
			Integer.from_user_input("1").should == 1
			Integer.from_user_input(" 124342").should == 124342
			Integer.from_user_input(" 4234 ").should == 4234
		end
		it "Should not accept other strings or objects as integers" do
			Integer.from_user_input("boom!").should be_nil
			Integer.from_user_input("1.223").should be_nil
			Integer.from_user_input(1.234).should be_nil
		end
		it "Should accept an equal integer object or string on the instance method" do
			1.from_user_input(1).should == 1
			1.from_user_input("1").should == 1
		end
		it "Should not accept other numbers, strings, or values on the instance method" do
			1.from_user_input(324).should be_nil
			1.from_user_input("boom!").should be_nil
			1.from_user_input("123").should be_nil
			1.from_user_input(1.23).should be_nil
		end
	end
	
	describe Float do
		it "Should take a Float or Integer object as an float" do
			Float.from_user_input(1.23).should == 1.23
			Float.from_user_input(1).should == 1.0
		end
		it "Should take a string with an acceptable format (including leading and trailing whitespace) as an float object" do
			Float.from_user_input("1.32").should == 1.32
			Float.from_user_input(" 1243.42").should == 1243.42
			Float.from_user_input(" 42.34 ").should == 42.34
			Float.from_user_input("1").should == 1.0
		end
		it "Should not accept other strings or objects as floats" do
			Float.from_user_input("boom!").should be_nil
		end
		it "Should accept an equal float object or string on the instance method" do
			(1.23).from_user_input(1.23).should == 1.23
			(1.23).from_user_input("1.23").should == 1.23
		end
		it "Should not accept other numbers, strings, or values on the instance method" do
			(1.23).from_user_input(324.34).should be_nil
			(1.23).from_user_input("boom!").should be_nil
			(1.23).from_user_input("123").should be_nil
			(1.23).from_user_input(1).should be_nil
		end
	end
	
	describe Regexp do
		it "Should accept a matching regex and return the match object" do
			/abba/.from_user_input("yabbadabbadoo").should be_kind_of(MatchData)
		end
		it "Should not accept a non-matching regex and return nil" do
			/abba/.from_user_input("boom").should be_nil
		end
		it "Should not accept non-strings" do
			/abba/.from_user_input(1).should be_nil
		end
	end
	
	describe Range do
		it "Should accept any value within the given range, but none outside" do
			(1..5).from_user_input(1).should == 1
			(1..5).from_user_input(50).should be_nil
		end
	end
	
	describe Array do
		it "Should always turn the input into an array if it isn't already" do
			Array.from_user_input(1).should == [1]
			Array.from_user_input([1]).should == [1]
			[Integer].from_user_input(1).should == [1]
		end
		it "Should raise an ArgumentError if you try to use it on an incorrect array instance" do
			proc {
				[].from_user_input([1])
			}.should raise_error(ArgumentError)
			proc {
				[1,2,3].from_user_input([1])
			}.should raise_error(ArgumentError)
		end
		it "Should do a recursive check on the input based on the type of the first element in the instance method" do
			[Integer].from_user_input([1, 2, 3]).should == [1, 2, 3]
			[Integer].from_user_input([1, 2, 3, "blah"]).should == [1, 2, 3]
			[[Integer]].from_user_input([[1,2,3],[4,5,6]]).should == [[1,2,3],[4,5,6]]
			[[Integer]].from_user_input([[1,2,3],4]).should == [[1,2,3],[4]] # this behaviour is questionable, but follows from useful behaviour in the first Array spec.
			[[Integer]].from_user_input([[1,2,3],"boom"]).should == [[1,2,3]]
		end
	end
	
	describe Hash do
		it "Should raise an ArgumentError if you try to use it on an incorrect hash instance" do
			proc {
				{}.from_user_input({})
			}.should raise_error(ArgumentError)
			proc {
				{:x=>:y, :z=>:a}.from_user_input({})
			}.should raise_error(ArgumentError)
		end
		it "Should return nil for a non-hash" do
			{1 => 2}.from_user_input(1).should be_nil
		end
		it "Should do a recursive check on the key/value pair passed in." do
			{String=>1}.from_user_input({"blah"=>1, "blorp"=>2}).should == {"blah"=>1}
			{String=>{Integer=>String}}.from_user_input({"boom"=>{1=>"stuff"}, "floom"=>"wat"}).should == {"boom"=>{1=>"stuff"}}
		end
	end
	
	describe Set do
		it "Should return an item if it can be validated as being in the Set" do
			set = Set["a", "b", 1, "23.4", 34.2]
			set.from_user_input("a").should == "a"
			set.from_user_input(1).should == 1
			set.from_user_input(23.4).should == "23.4"
			set.from_user_input("34.2").should == 34.2
		end
	end
	
	describe Symbol do
		it "Should raise an error if you try to take user input as a symbol, because that's dumb" do
			proc {
				Symbol.from_user_input(:BOOM)
			}.should raise_error(ArgumentError)
		end
		
		it "Should return the symbol if both can be converted to the same string, nil otherwise" do
			:blah.from_user_input("blah").should == :blah
			:blah.from_user_input(:blah).should == :blah
			:blah.from_user_input("boom").should be_nil
		end
	end
	
	describe IPAddr do
		it "Should return an IPAddr object if the string given it is a valid ip address." do
			IPAddr.from_user_input("127.0.0.1").should == IPAddr.new("127.0.0.1")
			IPAddr.from_user_input("::d234").should == IPAddr.new("::d234")
		end
	end
	
	class TestClass
		attr :v
		def initialize(v = 0)
			@v = v
		end
		def ==(o)
			v == o.v
		end
	end
	class DerivedTestClass < TestClass
	end
	
	describe Class do
		it "Should treat itself or a derived class as acceptable" do
			TestClass.from_user_input(TestClass).should == TestClass
			TestClass.from_user_input(DerivedTestClass).should == DerivedTestClass
			TestClass.from_user_input(String).should be_nil
		end
		
		it "Should pass through an instance of an arbitrary class given if the instance is of the same class" do
			tci = TestClass.new
			dtci = DerivedTestClass.new
			TestClass.from_user_input(tci).should == tci
			TestClass.from_user_input(dtci).should == dtci
			TestClass.from_user_input("").should be_nil
		end
	end
	
	describe Object do
		it "Should treat an arbitrary object (that doesn't have a more detailed implementation above) as the same if they test equal" do
			TestClass.new(1).from_user_input(TestClass.new(1)).should == TestClass.new(1)
			TestClass.new(1).from_user_input(TestClass.new(2)).should be_nil
		end
	end
end
