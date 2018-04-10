require_relative 'command'
class Destroy < Command
  NAME = "destroy"

  PREFIXES = ['destroy', 'dest']
  SHORTCUT = nil

  HELP = "destroy <ref> - Destroys an object"

	def process(thing, command)
		if @parts.size == 2
			t = find_thing(thing, @parts[1..-1].join(' '))
			if t
				if t.user_can_edit?(thing) and t != thing
					t.destroy
					return("#{t.name_ref} destroyed!\n")
				else
					return("Permission denied.\n")
				end
			else
				return("Object not found!\n")
			end
		else
			return("Destroy requires an object number.\n")
		end
	end

	def name
		return NAME
	end

end
