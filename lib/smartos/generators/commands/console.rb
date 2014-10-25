module SmartOS
  module Generators
    module Commands

      def self.included base
        base.extend ClassMethods
      end

      module ClassMethods
        def console(args)
          puts "Console!!!! #{args}"
        end
      end

    end
  end
end