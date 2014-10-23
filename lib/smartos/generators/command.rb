module SmartOS
  module Generators
    class Command
      def self.run(command, args)
        puts "#{command} (#{args.join(',')})"
      end
    end
  end
end