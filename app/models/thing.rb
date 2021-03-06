require 'securerandom'
class Thing < ActiveRecord::Base
	belongs_to :owner, foreign_key: 'owner_id', class_name: 'Thing'
	belongs_to :location, foreign_key: 'location_id', class_name: 'Thing'
	belongs_to :destination, foreign_key: 'destination_id', class_name: 'Thing'
	has_many :things, foreign_key: 'location_id'
	has_many :codes
	has_many :actions
	has_many :atts

	before_create :reset_key

	def name_ref
		return "#{self.name} (#{self.id})"
	end


	def name_ref_color
		return "#{self.name} " + "(#{self.id})".colorize(:light_black)
	end

	def user_can_edit?(user)
		return self == user || self.owner == user || user.wizard?
	end

	def broadcast(connections, user, message)
		for thing in self.things.where(["id != ?", self.id])
			# puts "Found: #{thing.name}"

			if thing.kind == 'object' and thing != self
				# puts "EXECUTE: #{thing.name_ref} - #{self.name_ref}"
				# thing.execute('receive', message)
			else
				em = connections[thing.id]
				if em and em.get_user != user
					# puts "--+ Broadcasting to: #{em}"
					em.send_data(message)
				end
			end
		end
	end

	def receive_message(from, message)
		message = '' unless message
		message = "#{message}"

		# puts "#{self.name_ref} received #{message}"
		em = CONNECTIONS[self.id]
		if em
			em.set_user(self)
			em.send_data("#{from.name}: #{message.gsub("\\n", "\n")}\n")
		end
		self.execute(from, 'receive', message)
	end

	def receive_raw_message(from, message)
		message = '' unless message
		message = "#{message}"
		puts "#{self.name_ref} received raw #{message}"
		em = CONNECTIONS[self.id]
		if em
			em.set_user(self)
			em.send_data(message.gsub("\\n", "\n") + "\n")
		end
		self.execute(from, 'receive', message)

	end


	def set_code(name, code)
		c = self.codes.where(name: name).first
		c = Code.new unless c
		c.thing = self
		c.name = name
		c.code = code
		c.save
	end

	def set_action(name, code)
		a = self.actions.where(name: name).first
		a = Action.new unless a
		a.thing = self
		a.name = name
		a.code = code
		a.save
	end

	def cmd(command)
		# puts "Thing command: #{command}"
		for c in COMMANDS
			# puts "Checking: #{c}"
			if c.should_respond?(command)
				# puts "  + Command responding: #{c.name}"
				result = c.execute(self, command)
				return(result)
			end
		end
	end

	def is_number?(obj)
			obj.to_s == obj.to_i.to_s
	end


	def execute(from, name, params)
		# puts "Execute: #{name}, #{params}"
		code = self.codes.where(name: name).first
		if code
	    cxt = V8::Context.new(timeout: 10000)
	    cxt['me'] = SafeThing.new(self, self)
			cxt['actor'] = SafeThing.new(from, self)
			cxt['params'] = params
			cxt['mush'] = MushInterface.new(self)
			# puts code.code
			begin
	     return(cxt.eval(code.code))
		 rescue V8::Error => e
			 puts "ERROR on #{self.name_ref}"

			 puts e.message
			 puts e.backtrace

				self.cmd("tell #{self.owner_id}=js error on #{self.id}: " + e.message)
				return(e)
			end
		end
	end

	def set(name, value)
		a = self.atts.where(name: name).first
		a = Att.new(thing_id: self.id, name: name) unless a
		# value.strip! if is_number?(value)
		a.value = value
		a.save
	end

	def get(name)
		a = self.atts.where(name: name).first
		return a.value if a
		return nil
	end

	def entered(thing)
		self.execute(thing, 'entered', thing.id)
	end

	def reset_key
		self.external_key = SecureRandom.uuid
	end


end
