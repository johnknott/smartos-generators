module SmartOS
  module Generators
    module Commands

      def self.included base
        base.extend ClassMethods
      end

      module ClassMethods
        def wizard(args)
          puts "Wizard!!!! #{args}"
        end
      end

    end
  end
end