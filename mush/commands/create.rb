require_relative 'command'
class Create < Command
  NAME = "create"

  PREFIXES = ['create']
  SHORTCUT = nil

  HELP = "create <name> - Creates a new object and places it in your inventory"

  def process(thing, command)
    new_thing = Thing.create(location_id: thing.id, owner_id: thing.id, kind: 'object', name: command.split(' ')[1..-1].join(' '), created_at: Time.now)
    return("Object created: #{new_thing.name} (##{new_thing.id})\n")
  end

  def name
    return NAME
  end
end
