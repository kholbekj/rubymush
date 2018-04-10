require_relative 'command'
class Drop < Command
  NAME = "drop"

  PREFIXES = ['drop']
  SHORTCUT = nil

  HELP = "drop <ref> - Drops an object from your inventory into your current location"

  def process(thing, command)
		if @parts.size > 1
			t = find_thing(thing, @parts[1..-1].join(' '))
			if t and t.location == thing
				t.location_id = thing.location_id
				t.save
				t.reload
				thing.location.broadcast(CONNECTIONS, thing, "#{thing.name} dropped #{t.name}.\n")
				return("You drop #{t.name_ref}\n")
			else
				return("You're not holding that.\n")
			end
		else
			return("What do you want to drop?\n")
		end
	end

	def name
		return NAME
	end

end
