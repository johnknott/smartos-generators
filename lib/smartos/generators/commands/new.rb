# Class to handle 'smartos new <name>' command
class New < SmartOS::Generators::Command
  include SmartOS::Configure::ConfigureGz

  # Creates a new SmartOS infrastructure project
  # @param args arguments to be parsed
  # @return [void]
  def perform(args)
    opts = Slop.parse!(args) do
      banner (<<-eos
      Usage:
        smartos new <name>

      Description:
        Creates a new SmartOS virtual infrastructure project.

        Asks some questions about the topology of your network and then creates configuration
        files to prepare your Global Zone. After this command has run, use 'smartos generate'
        to generate VM definitions. And finally, run 'smartos up' to actaully create your VMs.

      eos
      ).strip_indent
    end

    if args.size != 1
      say opts
      exit
    end

    new_project(args.first)
  end

  # Creates a new SmartOS infrastructure project
  # @param name [String] String containing a name for the project.
  # @return [void]
  def new_project(name)
    path = File.expand_path(name)
    if Dir.exist?(path)
      say "#{path} already exists. Please choose a directory name that doesn't already exist.".red
      exit
    end

    @gz_info = new_global_zone
    @gz_info.serialize(path)

    say "You have now configured your SmartOS virtual infrastructure. Inspect it, then run "\
         "'smartos up' to build it!".green
  end

end