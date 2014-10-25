module SmartOS
  module Generators
    module Commands

      def self.included base
        base.extend ClassMethods
      end

      module ClassMethods
        def down(args)
          puts "Down!!!! #{args}"
        end
      end

    end
  end
end