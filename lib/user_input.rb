# Adds the method from_user_input to various built-in classes as both a class and instance method. 
# On a class, the method returns a validated instance of that class if it can be coerced into one 
# (or nil if not). On an instance, it validates more strictly against the value of that instance.

class String
	# All strings validate as strings
	def String.from_user_input(value)
		return value.to_s
	end

	# instance form does a straight comparison of the string with self.
	def from_user_input(value)
		if (self == value.to_s)
			return value.to_s
		else
			return nil
		end
	end
end

class Boolean
	# Must be a string that is either "true" or "false"
	def Boolean.from_user_input(value)
		if (value.kind_of?(TrueClass) || value.kind_of?(FalseClass) ||
			  /(true|false|on|off|y|n|enabled|disabled)/ =~ value.to_s)
			return !!(/(true|on|y|enabled)/ =~ value.to_s)
		else
			return nil
		end
	end
end

class TrueClass
	# Either a 'positive' string or an actual instance of true.
	def from_user_input(value)
		if (value.kind_of?(TrueClass) || /(true|on|y|enabled)/ =~ value.to_s)
			return true
		else
			return nil
		end
	end
end

class FalseClass
	# Either a 'negative' string or an actual instance of false.
	def from_user_input(value)
		if (value.kind_of?(FalseClass) || /(false|off|n|disabled)/ =~ value.to_s)
			return false
		else
			return nil
		end
	end
end

class Date
	# Check for a string of the regex /[0-9]{1,2}\/[0-9]{1,2}\/[0-9]{4}/
	# and make a Date object out of it
	def Date.from_user_input(value)
		if (value.kind_of?(Date))
			return value
		end
		begin
			return Date.parse(value.to_s)
		rescue ArgumentError
			return nil
		end
	end
end

class Integer
	# All characters must be numbers, except for the first which may be -
	def Integer.from_user_input(value)
		if (value.kind_of?(Integer) || /^\s*-?[0-9]+\s*$/ =~ value.to_s)
			return value.to_i
		else
			return nil
		end
	end

	# instance form does a straight comparison of value.to_i with self.
	def from_user_input(value)
		if (!value.kind_of?(Float) && self == value.to_i)
			return value.to_i
		else
			return nil
		end
	end
end

class Float
	# All characters must be numbers, except there can be up to one decimal
	# and a negative sign at the front
	def Float.from_user_input(value)
		if (value.kind_of?(Float) || /^\s*-?[0-9]*(\.[0-9]+)?\s*$/ =~ value.to_s)
			return value.to_f
		else
			return nil
		end
	end

	# instance form does a straight comparison of value.to_f with self.
	def from_user_input(value)
		if (self == value.to_f)
			return value.to_f
		else
			return nil
		end
	end
end

class Regexp
	# Returns the string if value matches self's regex, returns nil otherwise.
	def from_user_input(value)
		if (value.kind_of?(String) && matches = self.match(value))
			return matches
		else
			return nil
		end
	end
end

class Range
	def from_user_input(value)
		value = self.first.class.from_user_input(value)

		if(!value || !(self === value))
			return nil
		end

		return value
	end
end

class Array
	def Array.from_user_input(value)
		return [*value]
	end
	
	# Checks each element of the value array to ensure that they match against
	# the first element of self
	def from_user_input(value)
		value = [*value]
		# eliminate the obvious
		if (self.length != 1)
			raise ArgumentError, "Must supply only one element to an array you're calling from_user_input on."
		end
		innertype = self[0]
		# now check whether the inner elements of the array match
		output = value.collect {|innervalue|
			# if innertype is not an array, but value is, we need to flatten it
			if (!innertype.kind_of?(Array) && innervalue.kind_of?(Array))
				innervalue = innervalue[0]
			end
			innertype.from_user_input(innervalue); # returns
		}.compact()

		if (output.length > 0)
			return output
		else
			return nil
		end
	end
end

class Hash
	def from_user_input(value)
		if (self.length != 1)
			raise ArgumentError, "Must supply only one element to a hash you're calling from_user_input on."
		end
		if (!value.kind_of?(Hash))
			return nil
		end
		keytype = nil
		valtype = nil
		self.each {|k,v| keytype = k; valtype = v}
		output = {}
		value.each {|k, v|
			if (!(k = keytype.from_user_input(k)).nil? && !(v = valtype.from_user_input(v)).nil?)
				output[k] = v
			end
		}
		if (output.length > 0)
			return output
		else
			return nil
		end
	end
end

class Set
	def from_user_input(value)
		each {|i|
			val = i.from_user_input(value)
			return val if val
		}
		return nil
	end
end

class Symbol
	def Symbol.from_user_input(value)
		raise ArgumentError, "You should never arbitrarily turn user input into symbols. It can cause leaks that could lead to DoS."
	end

	# instance form does a straight comparison of value.to_sym with self.
	def from_user_input(value)
		if (self.to_s == value.to_s)
			return self
		else
			return nil
		end
	end
end

class IPAddr
	def IPAddr.from_user_input(value)
		if (value.kind_of?(self))
			return true
		end
		begin
			return self.new(value.to_s)
		rescue ArgumentError
			return nil
		end
	end
end

class Class
	def from_user_input(value)
		if (value.kind_of?(Class) && value <= self)
			return value
		elsif (value.kind_of?(self))
			return value
		end
		return nil
	end
end

class Object
	def from_user_input(value)
		if (value == self)
			return value
		end
		return nil
	end
end
