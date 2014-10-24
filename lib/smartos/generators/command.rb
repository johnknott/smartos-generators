require 'highline/import'

module SmartOS
  module Generators
    class Command
      def self.run
        
        opts = Slop.parse!(ARGV, help: true) do
          banner 'Usage: smartos [options]'

          on 'name', 'Your name'
          on 'p', 'password', 'An optional password', argument: :optional
          on 'v', 'verbose', 'Enable verbose mode'
        end

      if ARGV!= 1
        puts opts.to_s
      end

      end
    end
  end
end






=begin
puts "#{command} (#{args.join(',')})"
        ask("Company?  ") { |q| q.default = "none" }
        puts ask("Interests?  (comma sep list)  ", lambda { |str| str.split(/,\s*/) })
        say("This should be <%= color('bold', BOLD, :blue) %>!")

        say("\nYou can even build shells...")
        loop do
          choose do |menu|
            menu.layout = :menu_only

            menu.shell  = true

            menu.choice(:load, "Load a file.") do |command, details|
              say("Loading file with options:  #{details}...")
            end
            menu.choice(:save, "Save a file.") do |command, details|
              say("Saving file with options:  #{details}...")
            end
            menu.choice(:quit, "Exit program.") { exit }
          end
        end
=end
