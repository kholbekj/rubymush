require_relative 'command'
class Floating < Command
  NAME = "floating"

  PREFIXES = ['floating']
  SHORTCUT = nil

  HELP = "floating - Lists your floating objects."

	def process(thing, command)
		things = Thing.where(["owner_id = ? and location_id is null", thing.id])
		back = ""
		if things.size > 0
			for t in things
				back << "#{t.name_ref}\n"
			end
			return back
		else
			return "No floating objects found.\n"
		end
	end

	def name
		return NAME
	end

end
