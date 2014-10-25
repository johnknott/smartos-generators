module SmartOS
  module Generators
    class Command

      USAGE = <<-eos
      Usage:
        smartos <command> [options]

        For in depth help run:
        smartos <command> --help

      Commands:
        new                     # Create a new SmartOS infrastructure project.
        up                      # Create and configure machines you have defined in your project.
        down                    # Destroy all or part of your infrastructure.
        console                 # Start an interactive ruby console in the context of a Global Zone.
        wizard                  # Start the wizard tool. Useful for one off tasks such as migrating VMs.
      eos

      def self.run(command, args)
        Object.const_get(command.capitalize).perform(args)
      end

      def self.usage
        USAGE.gsub /^#{USAGE[/\A\s*/]}/, ''
      end

    end
  end
end