module SmartOS
  module Generators
    class Command
      attr_accessor :console

      USAGE_OUTSIDE_PROJECT = <<-eos
      Usage:
        smartos <command> [options]

        For in depth help run:
        smartos <command> --help

      Commands:
        new                     # Create a new SmartOS infrastructure project.
      eos

      USAGE_WITHIN_PROJECT = <<-eos
      Usage:
        smartos <command> [options]

        For in depth help run:
        smartos <command> --help

      Commands:
        up                  # Create and configure machines you have defined in your project.
        down                # Destroy all or part of your infrastructure.
        console             # Start an interactive ruby console in the context of a Global Zone.
        wizard              # Start the wizard tool. Useful for one off tasks such as migrating VMs.
      eos

      def self.run(command, args)
        Object.const_get(command.capitalize).new.perform(args)
      end

      def self.usage(within_project)
        str = within_project ? USAGE_WITHIN_PROJECT : USAGE_OUTSIDE_PROJECT
        strip_heredoc(str)
      end

      def initialize
        @console = HighLine.new
      end

    end
  end
end
