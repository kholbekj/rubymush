require_relative 'command'
class Who < Command
  NAME = "who"

  PREFIXES = ['who']
  SHORTCUT = nil

  HELP = "who - Lists currently connected players"

  def process(thing, command)
    back = "Name\t\tIdle\t\tDoing\n".colorize(:bold)
    for player in Thing.where(connected: true)
      back << "#{player.name}\t\t#{time_ago_in_words(player.last_interaction_at)}\t\t#{player.doing}\n"
    end
    return(back)
  end

  def name
    return NAME
  end
end
