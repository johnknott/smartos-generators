class New < SmartOS::Generators::Command
  def self.perform(args) 
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


  end
end