require_relative 'command'
class Doing < Command
  NAME = "doing"
  HELP = "doing <message> - Sets your \"doing\" message, as seen in the \"who\" command."

  def process(thing, command)
		message = @parts[1..-1].join(' ')
		thing.doing = message
		thing.save
		"Doing set: #{message}\n"
	end
end
