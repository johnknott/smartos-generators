module SmartOS
  module Generators
    module Commands

      def self.included base
        base.extend ClassMethods
      end

      module ClassMethods
        def new(args)
          puts "New!!!! #{args}"
        end
      end

    end
  end
end