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
end