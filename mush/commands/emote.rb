require_relative 'command'
class Emote < Command
  NAME = "Emote"
  PARAMETER_COUNT = 1

  PREFIXES = [':', 'emote']
  SHORTCUT = ':'

  HELP = ":<message> - Emotes in your current location"

	def process(thing, command)
		message = @parts[1..-1].join(' ')
		message = command[1..-1] if command.start_with?(':')
		thing.location.broadcast(CONNECTIONS, thing, "#{thing.name} ".colorize(:light_blue) + "#{message}\n")
		return("#{thing.name} ".colorize(:light_blue) + "#{message}\n")
	end

	def name
		return NAME
	end
end
