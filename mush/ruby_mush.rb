require 'rubygems'
require 'eventmachine'
require 'active_record'
require 'colorize'
require 'v8'
require 'yaml'
require 'concurrent'
require 'bcrypt'
require 'pry'

puts "--+ Starting RubyMush..."

# Let's make sure we're at the root dir.
root_dir = File.expand_path('..', __dir__)
Dir.chdir(root_dir)

# And let's go ahead and load files from there
$LOAD_PATH.unshift root_dir

if ARGV.size == 0
  abort("Usage: ruby ruby_mush.rb <environment>")
end

# Config
START_LOCATION = 1 # Starting room for new users
PORT = 8081 # TCP port

CONNECTIONS = Hash.new
COMMANDS = Array.new

db_info = YAML.load(File.open('config/database.yml').read)[ARGV[0]]
db_path = '' + db_info['database'] if db_info['adapter'] == 'sqlite3'
ActiveRecord::Base.establish_connection(
  adapter: db_info['adapter'],
  database: db_path,
  username: db_info['username'],
  password: db_info['password']
)

require 'app/models/thing'
require 'app/models/code'
require 'app/models/action'
require 'app/models/att'
require 'app/models/queued_command'

require 'mush/lib/safe_thing'

require 'mush/lib/mush_interface'

puts "--+ Loading commands:"

Dir.glob('mush/commands/*rb') do |item|
	require(item.split('.')[0])
  if item != 'mush/commands/command.rb'
		klass = Object.const_get(
      File::basename(item.split('.')[0], ".rb")
      .split("_")
      .map(&:capitalize)
      .join("")
    )
    puts "  + Loaded: #{klass}"
    COMMANDS << klass.new
  end
end


Thing.where(kind: 'player', connected: true).each do |player|
  player.update_attribute(:connected, false)
end

if ARGV[1] == "update-passwords"
  puts "--+ Updating passwords:"
  Thing.where(kind: 'player').each do |player|
    salt = BCrypt::Engine.generate_salt
    encrypted_password = BCrypt::Engine.hash_secret(player.password, salt)
    player.password = encrypted_password
    player.salt = salt
    puts "  + Updated password for: #{player.name}"
    player.save
  end
end

module MushServer
  @user = nil
  @http = false

  def get_user
    return @user
  end

  def set_user(user)
    @user = user
  end

  def time_ago_in_words(t)
    seconds = Time.now.to_i - t.to_i
    if seconds > 86400
      return "#{seconds/86400}d"
    end
    if seconds > 3600
      return "#{seconds/3600}h"
    end
    if seconds > 60
      return "#{seconds/60}m"
    end
    return "#{seconds}s"
  end

  def post_init
    puts "--+ New connection"
    send_data File.read('mush/welcome.txt') unless @http
  end

  def is_number?(obj)
    obj.to_s == obj.to_i.to_s
  end

  def find_thing(q)
    q.strip!
    # puts "--+ Finding thing: #{q}"
    if is_number?(q)
      return Thing.where(id: q).first
    elsif q.downcase == 'here'
      return @user.location
    elsif q.downcase == 'me'
      return @user
    else
      return Thing.where(["name like ? and location_id in (?)", "#{q}%", [@user.id, @user.location_id]]).first
    end
  end


  def connect_user(user)
    user.connected = true
    user.last_login_at = Time.now
    user.last_interaction_at = Time.now
    user.save
    CONNECTIONS[user.id] = self
    user.location.broadcast(CONNECTIONS, user, "#{user.name} has connected.\n")
    puts "--+ #{user.name} logged in"

    COMMANDS.each do |c|
      # puts "Checking: #{c.name}"
      if c.name == 'look'
        result = c.execute(@user, "look")
        send_data(result) if result
        break
      end
    end

    user.location.entered(user)

    # for c in CONNECTIONS
    # 	puts "  + Connected user: #{c.get_user}"
    # end
  end

  def parse_command(command)
    command.strip!
    return if command == nil
    parts = command.split(' ')
    if @user == nil

      # Login commands

      if command == 'a' && ARGV[1] == 'test'
        @user = Thing.where(name: 'Benji', kind: 'player').first
        connect_user(@user)
        send_data("Welcome back #{@user.name}!\n")
        return
      end

      if command == 'b' && ARGV[1] == 'test'
        @user = Thing.where(name: 'test', kind: 'player').first
        connect_user(@user)
        send_data("Welcome back #{@user.name}!\n")

        return
      end


      if command.downcase.start_with? 'create'
        if command.split(' ').size == 3
          salt = BCrypt::Engine.generate_salt
          encrypted_password = BCrypt::Engine.hash_secret(command.split(' ')[2], salt)
          @user = Thing.create(name: command.split(' ')[1], password: encrypted_password, salt: salt, last_login_at: Time.now, kind: 'player', location_id: START_LOCATION, last_interaction_at: Time.now)
          connect_user(@user)
          send_data("User created. Welcome!\n")
        else
          send_data("Create requires a name and password.\n")
        end
        return
      end

      if command.downcase.start_with? 'connect' or command.downcase.start_with? 'con'
        if command.split(' ').size == 3

          @user = Thing.where(name: command.split(' ')[1]).first
          if @user
            encrypted_password = BCrypt::Engine.hash_secret(command.split(' ')[2], @user.salt)
            if @user.password == encrypted_password
              connect_user(@user)
              send_data("Welcome back #{@user.name}!\n")
            else
              send_data("Name or password incorrect!\n")
            end
          else
            send_data("Name or password incorrect!\n")
          end
        else
          send_data("Connect requires a name and password.\n")
        end
        return
      end
      return
    else
      @user.last_interaction_at = Time.now
      @user.save

      # General commands

      # puts "--+ Command received: #{command}"

      return if command == nil || command == ''

      COMMANDS.each do |c|
        # puts "Checking: #{c}"
        if c.should_respond?(command)
          # puts "  + Command responding: #{c.name}"
          result = c.execute(@user, command)
          send_data(result) if result
          return
        end
      end
    end

    # Check for exits

    destination = nil
    @user.location.things.where(kind: 'exit').each do |thing|
      if thing.name.downcase == command.downcase
        destination = thing.destination
        break
      end

      if thing.name.include? '<'
        name = thing.name.split('<')[0].strip.downcase
        if command.downcase == name
          destination = thing.destination
          break
        end
      end

      if thing.name.include? '<' and thing.name.include? '>'

        shortcut = thing.name.split('<')[1].split('>')[0].downcase
        if command.downcase == shortcut
          destination = thing.destination
          break
        end
      end
    end

    if destination
      send_data("You enter #{thing.name}.\n")
      @user.location.broadcast(CONNECTIONS, @user, "#{@user.name} exited to #{thing.name}\n")
      destination.broadcast(CONNECTIONS, @user, "#{@user.name} entered from #{@user.location.name}\n")
      @user.location = thing.destination
      @user.save

      COMMANDS.each do |c|
        if c.name == 'look'
          result = c.execute(@user, "look")
          send_data(result) if result
          break
        end
      end
      destination.entered(@user)
      return
    end

    # Check for commands

    # Self, location, things in location

    cmd = command.split(' ')[0].downcase

    # puts "--+ Checking for action: #{cmd}"
    action = @user.actions.where(name: cmd).first

    action ||= @user.location.actions.where(name: cmd).first

    unless action
      @user.things.where(kind: 'object').each do |thing|
        action = thing.actions.where(name: cmd).first
        break if action
      end
    end

    unless action
      @user.location.things.where(kind: 'object').each do |thing|
        action = thing.actions.where(name: cmd).first
        break if action
      end
    end

    if action
      puts "--+ Running action: #{action.name} on #{action.thing.name_ref}"
      code = action.thing.codes.where(name: action.code).first
      if code
        begin
          action.thing.execute(@user, action.code, command.split(' ')[1..-1].join(' '))
          return(nil)
        rescue Exception => e
          return("Error: #{e}\n")
          puts e.backtrace
        end
      else
        return("Code #{name} not found on #{action.thing.name_ref}!\n")
      end
      return
    end

    send_data("What was that, #{@user.name}?\n".colorize(:red))
  end

  def receive_data data
    parse_command(data)
    #send_data ">>>you sent: #{data}"
    #close_connection if data =~ /quit/i
  end

  def unbind
    puts "--+ Connection closed"
    if @user
      @user.connected = false
      @user.save
      CONNECTIONS.delete(@user.id)
      @user.location.broadcast(CONNECTIONS, @user, "#{@user.name} has disconnected.\n")
      puts "--+ #{@user.name} logged out"
    end
  end
end


# Run tick code on each thing
task = Concurrent::TimerTask.new {
  # puts "--+ Tick!"
  Code.where(name: 'tick').each do |code|
    code.thing.execute(nil, code.name, nil)
  end
}

task.execution_interval = 5 #=> 5 (default)
task.timeout_interval = 30  #=> 30 (default)

task.execute


# Run any tasks queued from web interface
cmdTask = Concurrent::TimerTask.new {
  # puts "--+ Running queued commands!"

  QueuedCommand.each do |cmd|
    # puts cmd
    thing = cmd.thing
    if thing
      thing.execute(nil, cmd.name, cmd.parameters)
    end
    cmd.destroy
  end

}

cmdTask.execution_interval = 5 #=> 5 (default)
cmdTask.timeout_interval = 1000  #=> 30 (default)

cmdTask.execute



EventMachine.run {
  puts "--+ Started!"
  EventMachine.start_server "0.0.0.0", PORT, MushServer
}
