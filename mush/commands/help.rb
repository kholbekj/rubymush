require_relative 'command'
class Help < Command
  NAME = "help"
  PARAMETER_COUNT = 0

  PREFIXES = ['help']
  SHORTCUT = '?'

  HELP = "help - Shows help index"

  def process(thing, command)
		if @parts.size == 1
			commands = ""
			for c in COMMANDS
				commands << c.name.downcase << "\n"
			end
			return("RubyMush Help\n\n#{commands}\nFor more information type: help <command name>\n")
		else
			for c in COMMANDS
				if c.should_respond? @parts[1..-1].join(' ')
					return c.help + "\n"
				end
			end
		end
    "Could not find help for that.\n"
	end

	def name
		return NAME
	end

end
