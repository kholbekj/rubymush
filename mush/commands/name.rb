require_relative 'command'
class Name < Command
  NAME = "name"

  PREFIXES = ['name']
  SHORTCUT = nil

  HELP = "name <ref>=<description> - Sets the name of an object"

	def process(thing, command)
		if @parts.size >= 2
			@parts.shift
			@parts = @parts.join(' ').split('=')
			t = find_thing(thing, @parts[0])
			if t
				if t.user_can_edit?(thing)
					t.name = @parts[1..-1].join('=').strip
					t.save
					return("Name set for #{t.name_ref}.\n")
				else
					return("Permission denied.\n")
				end
			else
				return("Object not found.\n")
			end

		else
			return("Usage: name <object name or ref>=<new name>")
		end
	end

	def name
		return NAME
	end

end
