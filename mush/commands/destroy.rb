require_relative 'command'
class Destroy < Command
  NAME = "destroy"
  HELP = "destroy <ref> - Destroys an object"

	def process(thing, command)
    return "Destroy requires an object number.\n" unless @parts.size == 2

    t = find_thing(thing, @parts[1..-1].join(' '))

    return "Object not found.\n" unless t
    return "Permission denied.\n" unless t.user_can_edit?(thing)

    t.destroy

    "#{t.name_ref} destroyed!\n"
  end
end
