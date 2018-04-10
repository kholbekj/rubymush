require_relative 'command'
class Chown < Command
  NAME = "chown"
  HELP = "chown <ref1>=<ref2> - Sets <ref2> as owner of <ref1>"

  def process(thing, command)
    return "Usage: description <object name or ref>=<description>\n" unless @parts.size >= 2

    @parts.shift
    @parts = @parts.join(' ').split('=')

    t = find_thing(thing, @parts[0])
    dest = find_thing(thing, @parts[1])

    return "Object not found.\n" unless t
    return "Permission denied.\n" unless t.user_can_edit?(thing)
    return "New owner not found.\n" unless dest

    t.owner = dest
    t.save
    return("Ownership of #{t.name} changed to #{dest.name}.\n")
  end
end
