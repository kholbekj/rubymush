require_relative 'command'
class Describe < Command
  NAME = "describe"

  PREFIXES = ['describe', 'desc']
  SHORTCUT = nil

  HELP = "describe <ref>=<description> - Sets the description of an object"

  def process(thing, command)
    if @parts.size >= 2
      @parts.shift
      @parts = @parts.join(' ').split('=')
      t = find_thing(thing, @parts[0])
      if t
        if t.user_can_edit?(thing)
          t.description = @parts[1..-1].join('=').strip
          t.save
          return("Description set for #{t.name_ref}.\n")
        else
          return("Permission denied.\n")
        end
      else
        return("Object not found.\n")
      end

    else
      return("Usage: description <object name or ref>=<description>\n")
    end
  end

  def name
    return NAME
  end

end
