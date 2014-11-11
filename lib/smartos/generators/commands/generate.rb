# Class to handle 'smartos generate' command
class Generate < SmartOS::Generators::Command
  include SmartOS::Configure::ConfigureVm

  # Creates a new Virtual Machine Definition
  # @param args arguments to be parsed
  # @return [void]
  def perform(args)
    opts = Slop.parse!(args) do
      banner (<<-eos
      Usage:
        smartos generate <name>

      Description:
        Creates a new Virtual Machine definition within a SmartOS infrastructure project.

        Asks some questions about the specifications of the machine you want to be created and
        then creates a JSON machine definition automatically from a template.

        Create as many VMs as you need and then create this infrastructure with the 'smartos up' command.
      eos
      ).strip_indent
    end

    if args.size != 1
      say opts
      exit
    end

    new_vm(args.first)
  end

  # Creates a new Virtual Machine definition
  # @param name [String] Alias to be used for the VM
  # @return [void]
  def new_vm(name)
    
    # load settings
    #configure_virtual_machine()

    @gz_info = new_global_zone

    #system 'mkdir', '-p', path
    #say "Creating New SmartOS Infrastructure Project: #{name}".blue.bold
    #say "At path: #{path}".green

    say "You have now configured your SmartOS virtual infrastructure. Inspect it, then run "\
         "'smartos up' to build it!".green
  end
end

=begin
        if agree("Do you want to create your Virtual Machine definitions now?"){ |q| q.default = 'yes'}
          loop do
            gz_info.vm_definitions << configure_virtual_machine(gz_info)
            break unless agree("Finished configuring this VM. Add another?"){ |q| q.default = 'yes'}
          end
        else
          say "\nSkipping Machine definitions."
        end
=end
