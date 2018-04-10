require_relative 'command'
require_relative '../lib/broadcaster.rb'
class Emit < Command

  NAME = "emit"
  PARAMETER_COUNT = 1

  PREFIXES = ['emit']
  SHORTCUT = nil

  HELP = "emit <message> - Emits message by itself in current location"

	def process(thing, command)
		message = @parts[1..-1].join(' ')
		message = command[1..-1] if command.start_with?('"')
		b = Broadcaster.new(thing, CONNECTIONS)
		b.broadcast_location("#{message}\n")
		return("#{message}\n")
	end

	def name
		return NAME
	end
end
