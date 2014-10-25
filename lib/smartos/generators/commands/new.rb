class New < SmartOS::Generators::Command
  def perform(args) 
    opts = Slop.parse!(args) do
      banner Command.strip_heredoc <<-eos
      Usage:
        smartos new <name>

      Description:
        Creates a new SmartOS virtual infrastructure project.

        Asks some questions about the specifications of the machines you want
        to be created and the topology of your network and the and then creates
        configuration files and JSON machine definitions automatically from
        templates.

        This command can also help configure a VPN using OpenVPN and generate
        configuration files.

        You can then create this infrastructure with the 'smartos up' command.
      eos

      on 'v', 'verbose', 'Enable verbose mode'
    end

    if args.size != 1
      puts opts
      exit
    end

    new_project(args.first)

  end

  def new_project(name)
    path = File.expand_path(name)
    if Dir.exists?(path)
      puts "#{path} already exists. Please choose a directory name that doesn't already exist."
      exit
    end      

    system 'mkdir', '-p', path
    puts "Creating New SmartOS Infrastructure Project: #{name}".green
    puts "At path: #{path}".green

    loop do
      @hostname = ask "Please enter the IP address or hostname of your SmartOS Global Zone:"
      @info = SmartOS::GlobalZone.is_global_zone?(@hostname)
      break if @info
    end

    puts "Successfully connected to Global Zone #{@hostname} (#{@info})".green

  end
end