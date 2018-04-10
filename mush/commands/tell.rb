require_relative 'command'
class Tell < Command
  NAME = "tell"

  PREFIXES = ['tell']
  SHORTCUT = nil

  HELP = "tell <ref>=<message> - Privately sends <message> to <ref>"

  def process(thing, command)
    if @parts.size >= 2
      @parts.shift
      @parts = @parts.join(' ').split('=')
      t = find_thing(thing, @parts[0])
      if t
        message = @parts[1..-1].join('=').strip
        t.receive_message(thing, message)
        return("Told #{t.name}: #{message}.\n")
      else
        return("Object not found.\n")
      end

    else
      return("Usage: #{@help}\n")
    end
  end

  def name
    return NAME
  end

end
