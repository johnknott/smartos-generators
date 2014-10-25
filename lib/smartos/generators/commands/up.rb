module SmartOS
  module Generators
    module Commands

      def self.included base
        base.extend ClassMethods
      end

      module ClassMethods
        def up(args)
          puts "Up!!!! #{args}"
        end
      end

    end
  end
end