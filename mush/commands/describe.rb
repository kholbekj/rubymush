require_relative 'command'
class Describe < Command
  NAME = "describe"
  HELP = "describe <ref>=<description> - Sets the description of an object"

  def process(thing, command)
    return "Usage: description <object name or ref>=<description>\n" unless @parts.size >= 2

    @parts.shift
    @parts = @parts.join(' ').split('=')
    t = find_thing(thing, @parts[0])

    return "Object not found.\n" unless t
    return "Permission denied.\n" unless t.user_can_edit?(thing)

    t.description = @parts[1..-1].join('=').strip
    t.save

    "Description set for #{t.name_ref}.\n"
  end
end
