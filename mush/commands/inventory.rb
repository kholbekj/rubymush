require_relative 'command'
class Inventory < Command
  NAME = "inventory"

  PREFIXES = ['i', 'inv', 'inventory']
  SHORTCUT = nil

  HELP = "inventory - Shows your inventory."

	def process(thing, command)
		things = Thing.where(location: thing.id).order('name asc')
		back = "You are carrying:\n".colorize(:light_magenta)
		if things.size == 0
			back += "Nothing!\n"
		end
		for t in things
				back += "#{t.name_ref_color}\n"
		end
		return(back)
	end

	def name
		return NAME
	end

end
