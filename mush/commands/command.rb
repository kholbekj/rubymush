class Command

	def initialize
		@parameter_count = 0
		@prefixes = []
		@shortcut = nil
		@help = ""
		@broadcaster = nil
	end

  def execute(thing, command)
		@parts = command.split(' ')
		return(process(thing, command))
	end

	def should_respond?(c)
		# puts "Should respond? #{c}"
		parts = c.split(' ')
		if prefixes.include?(parts[0].downcase) or (shortcut and c.start_with? shortcut)
			return true
		end
	end

	def help
    self.class.const_get(:HELP)
	end

	def prefixes
    self.class.const_defined?(:PREFIXES) ? self.class.const_get(:PREFIXES) : [self.class.const_get(:NAME)]
	end

	def shortcut
    self.class.const_defined?(:SHORTCUT) ? self.class.const_get(:SHORTCUT) : nil
	end

  def name
    self.class.const_get(:NAME)
  end

	def time_ago_in_words(t)
		seconds = Time.now.to_i - t.to_i
		if seconds > 86400
			return "#{seconds/86400}d"
		end
		if seconds > 3600
			return "#{seconds/3600}h"
		end
		if seconds > 60
			return "#{seconds/60}m"
		end
		return "#{seconds}s"
	end


	def is_number?(obj)
			obj.to_s == obj.to_i.to_s
	end

	def find_thing(thing, q)
		q.strip!
		# puts "--+ Finding thing: #{q}"
		if is_number?(q)
			return Thing.where(id: q).first
		elsif q.downcase == 'here'
			return thing.location
		elsif q.downcase == 'me'
			return thing
		else
			return Thing.where(["name like ? and location_id in (?)", "#{q}%", [thing.id, thing.location_id]]).first
		end
	end

	def format(text)
		text.gsub('\\n', "\n").gsub('\\t', "\t")
	end


end
