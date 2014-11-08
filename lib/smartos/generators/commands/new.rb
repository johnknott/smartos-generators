class New < SmartOS::Generators::Command
  include SmartOS::Configure::VirtualMachine
  include SmartOS::Configure::GlobalZone

  # Creates a new SmartOS infrastructure project.
  # Every Command must implement 'perform'.
  # @param args arguments to be parsed
  # @return [void]
  def perform(args)
    opts = Slop.parse!(args) do
      banner (<<-eos
      Usage:
        smartos new <name>

      Description:
        Creates a new SmartOS virtual infrastructure project.

        Asks some questions about the specifications of the machines you want to be created and the
        topology of your network and then creates configuration files and JSON machine definitions
        automatically from templates.

        This command can also help configure a VPN using OpenVPN and generate configuration files.

        You can then create this infrastructure with the 'smartos up' command.
      eos
      ).strip_indent
    end

    if args.size != 1
      say opts
      exit
    end

    new_project(args.first)
  end

  # Creates a new SmartOS infrastructure project.
  # @param name [String] String containing a name for the project.
  # @return [void]
  def new_project(name)
    path = File.expand_path(name)
    if Dir.exist?(path)
      say "#{path} already exists. Please choose a directory name that doesn't already exist.".red
      exit
    end

    @gz_info = new_global_zone

    #system 'mkdir', '-p', path
    #say "Creating New SmartOS Infrastructure Project: #{name}".blue.bold
    #say "At path: #{path}".green

    say "You have now configured your SmartOS virtual infrastructure. Inspect it, then run "\
         "'smartos up' to build it!".blue
  end

end