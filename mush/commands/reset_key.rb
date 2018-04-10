require_relative 'command'
class ResetKey < Command
		NAME = "resetkey"

		PREFIXES = ['resetkey']
		SHORTCUT = nil

		HELP = "resetkey <ref> - Generates a new external key for <ref>"

	def process(thing, command)
		if @parts.size > 1
			t = find_thing(thing, @parts[1..-1].join(' '))
			if t
				if t.user_can_edit?(thing)
					t.reset_key
					t.save
					return("Return new key for #{t.name_ref}: #{t.external_key}\n")
				else
					return("Permission denied!\n")
				end
			else
				return("Object not found.\n")
			end
		else
			return("Object not found.\n")
		end
	end

	def name
		return NAME
	end

end
