require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'lib/user_input/type_safe_hash'

describe UserInput::TypeSafeHash do
	TypeSafeHash = UserInput::TypeSafeHash
	
	describe "initializer" do
		it "should take a normal hash as an argument" do
			TypeSafeHash.new(:a => :b).should == TypeSafeHash.new(:a => :b)
		end
		it "should take another type safe hash as an argument" do
			TypeSafeHash.new(TypeSafeHash.new(:a => :b)).should == TypeSafeHash.new(:a => :b)
		end
		it "should raise an error for anything else" do
			proc {
				TypeSafeHash.new("boom")
			}.should raise_error(ArgumentError)
		end
	end
	
	before :each do 
		@hash = TypeSafeHash.new("blah" => "blorp", 1 => 2, 3 => [1, 2, 3])
		@str_hash = TypeSafeHash.new("blah" => "waht", "woop" => "wonk", "woo" => "fluh")
	end
	
	it "should properly implement to_hash to return the original hash object" do
		@hash.to_hash.should be_kind_of(Hash)
	end
	
	it "should compare to another TypeSafeHash as equal if they have the same real hash" do
		(@hash == TypeSafeHash.new(@hash.to_hash)).should be_true
		(@hash == TypeSafeHash.new()).should be_false
	end
	it "should compare to any other object as not equal" do
		(@hash == Hash.new).should be_false
	end
	
	describe "fetch" do
		it "should validate as user input any requests for keys" do
			@hash.fetch("blah", String).should == "blorp"
			@hash.fetch("blah", /orp/)[0].should == "blorp".match(/orp/)[0]
			@hash.fetch("blah", Integer).should be_nil
			
			@hash.fetch(1, Integer).should == 2
			@hash.fetch(1, 2).should == 2
			@hash.fetch(1, 3).should be_nil
			
			@hash.fetch(3, [Integer]).should == [1,2,3]
		end
		
		it "should flatten an array value to a single value if the requested type is not an array" do
			@hash.fetch(3, Integer).should == 1
		end
		
		it "should take a default value for failed matching" do
			@hash.fetch("blah", /woople/, "woople").should == "woople"
		end
		
		it "should be aliased to the [] method" do
			@hash["blah", String].should == "blorp"
		end
	end
	
	it "should properly implement each_key" do
		keys = []
		@hash.each_key {|x| keys.push(x)}
		keys == @hash.to_hash.keys
	end
	
	it "should properly implement each_pair" do
		out = {}
		@str_hash.each_pair(String) {|key, val| out[key]=val}
		out.should == @str_hash.to_hash
	end
	
	it "should properly implement each_match, returning only keys that match the regex" do
		out = []
		@str_hash.each_match(/woo/, String) {|match, val| out.push([match[0],val]) }
		out.sort.should == [["woo", "fluh"], ["woo", "wonk"]].sort
	end
	
	it "empty? should return true for an empty hash and false for one with values" do
		@hash.empty?.should == false
		TypeSafeHash.new.empty?.should == true
	end
	
	it "should implement has_key? and all of its aliases (include?, key?, member?)" do
		@hash.has_key?(3).should be_true
		@hash.has_key?(4).should be_false
		@hash.include?(3).should be_true
		@hash.include?(4).should be_false
		@hash.key?(3).should be_true
		@hash.key?(4).should be_false
		@hash.member?(3).should be_true
		@hash.member?(4).should be_false
	end
	
	it "should implement inspect as an alias to its real hash's inspect" do
		@hash.inspect.should == @hash.to_hash.inspect
	end
	
	it "should implement keys as returning the real hash's keys, both sorted and unsorted" do
		@str_hash.keys.should == @str_hash.to_hash.keys
		@str_hash.keys(true).should == @str_hash.to_hash.keys.sort
	end
	
	it "should implement values as returning the values from the real hash" do
		@hash.values.should == @hash.to_hash.values
	end
	
	it "should return the number of items in the hash from length" do
		@hash.length.should == @hash.to_hash.length
	end
	
	it "should implement to_s as returning the internal hash's string representation" do
		@hash.to_s.should == @hash.to_hash.to_s
	end
	
	it "should implement TypeSafeHash.from_user_input as accepting only a hash" do
		TypeSafeHash.from_user_input({}).should == TypeSafeHash.new({})
		TypeSafeHash.from_user_input("Blah").should be_nil
	end
end