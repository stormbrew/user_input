require 'user_input'

module UserInput
	# Handles parsing command line options such that it terminates on the first
	# bareword argument, '--', or the end of the arguments. Uses from_user_input
	# to validate input if requested.
	class OptionParser
		Info = Struct.new(:short_name, :long_name, :description, :flag, :default_value, :value, :validate)
		class Info
			attr_accessor :short_name, :long_name, :description, :flag, :default_value, :value, :validate
			def initialize(short_name, long_name, description, flag, default_value, value, validate)
				@short_name, @long_name, @description, @flag, @default_value, @value, @validate =
				short_name, long_name, description, flag, default_value, value, validate
			end
			
			def value=(string)
				if (validate.nil?)
					@value = string
				elsif (validate.respond_to? :call) # it's a proc, call it and replace with return value
					@value = validate.call(string)
				else
					string = validate.from_user_input(string)
					if (!string)
						raise ArgumentError, "Validation of #{long_name} failed. Expected #{validate}" 
					end
					@value = string
				end
			end
		end
		
		# The prefix for the program in the usage banner. Used only if banner is nil.
		attr_accessor :program_prefix
		# The banner to display above the help. Defaults to nil, in which case it's generated.
		attr_writer :banner
		
		# If a block is passed in, it is given self.
		def initialize(program_prefix = $0)
			@options = {}
			@order = []
			@program_prefix = program_prefix
			@banner = nil
						
			if (block_given?)
				yield self
			end
		end
		
		def define_value(short_name, long_name, description, flag, default_value, validate = nil)
			short_name = short_name.to_s
			long_name = long_name.to_s
			
			if (short_name.length != 1)
				raise ArgumentError, "Short name must be one character long (#{short_name})"
			end
			if (long_name.length < 2)
				raise ArgumentError, "Long name must be more than one character long (#{long_name})"
			end
			
			info = Info.new(short_name, long_name, description, flag, default_value, nil, validate)
			@options[long_name] = info
			@options[short_name] = info
			
			@order.push(info)
			
			method_name = long_name.gsub('-','_')
			method_name << "?" if (flag)
			(class <<self; self; end).class_eval do
				define_method(method_name.to_sym) do
					return @options[long_name].value || @options[long_name].default_value
				end
			end
			
			return self
		end
		private :define_value

		# This defines a command line argument that takes a value.
		def argument(short_name, long_name, description, default_value, validate = nil, &block)
			if (default_value.nil?)
				raise ArgumentError, "Must provide a default value for optional argument."
			end
			return define_value(short_name, long_name, description, false, default_value, validate || block)
		end
		
		# This defines a command line argument that's either on or off based on the presense
		# of the flag.
		def flag(short_name, long_name, description, &block)
			return define_value(short_name, long_name, description, true, false, block)
		end
		
		# This produces a gap in the output of the help display but does not otherwise
		# affect the argument parsing.
		def gap(count = 1)
			1.upto(count) { @order.push(nil) }
		end
		
		def parse!(argv = ARGV)
			# this is a stack of arguments that need to have their values filled by subsequent arguments
			argument_stack = []
			
			while (argv.first)
				arg = argv.first
				
				# if there's a node on the argument stack, we fill it in.
				if (argument_stack.first)
					argument_stack.shift.value = arg
				else
					# figure out what type of argument it is
					if (match = arg.match(/^\-\-(.+)$/))
						arg_info = @options[match[1]]
						if (!arg_info)
							raise ArgumentError, "Unrecognized option #{match[1]}"
						end
						if (arg_info.flag)
							arg_info.value = true
						else
							argument_stack.push(arg_info)
						end
					elsif (match = arg.match(/^-(.+)$/))
						short_args = match[1].split("")
						short_args.each {|short_arg|
							arg_info = @options[short_arg]
							if (!arg_info)
								raise ArgumentError, "unrecognized option #{match[1]}"
							end
							if (arg_info.flag)
								arg_info.value = true
							else
								argument_stack.push(arg_info)
							end
						}
					else
						# unrecognized bareword, so bail out and leave it to the caller to figure it out.
						return argv
					end
				end
				
				argv.shift
			end
			
			# if we got here and there are still items on the argument stack,
			# we didn't get all the values we expected so error out.
			if (argument_stack.length > 0)
				raise ArgumentError, "Missing value for argument #{argument_stack.first.long_name}"
			end
			return argv
		end
		def parse(argv = ARGV)
			self.parse!(argv.dup)
		end
		
		# returns either the banner set with banner= or a simple banner
		# like "Usage: $0 [arguments]"
		def banner
			@banner || "Usage: #{program_prefix} [arguments]"
		end			
		
		def longest
			l = 0
			@options.keys.each {|opt|
				l = (opt.length > l)? opt.length : l
			}
			return l
		end
		
		# Outputs a help screen. Code largely taken from the awesome, but
		# not quite right for my needs, Clip (http://github.com/alexvollmer/clip)
		def to_s
			out = ""
			out << banner << "\n"
			
			@order.each {|option|
				if (option.nil?)
					out << "\n"
					next
				end
				
        line = sprintf("-%-2s --%-#{longest+6}s  ",
                       option.short_name,
                       option.long_name + (option.flag ? "" : " [VAL]"))

        out << line
        if (line.length + option.description.length <= 80)
          out << option.description
        else
          rem = 80 - line.length
          desc = option.description
          i = 0
          while (i < desc.length)
            out << "\n" if i > 0
            j = [i + rem, desc.length].min
            while desc[j..j] =~ /[\w\d]/
              j -= 1
            end
            chunk = desc[i..j].strip
            out << " " * line.length if i > 0
            out << chunk
            i = j + 1
          end
        end

        if (!option.flag)
          out << " (default: #{option.default_value})"
        end

        out << "\n"
      }
      return out
		end
	end
end