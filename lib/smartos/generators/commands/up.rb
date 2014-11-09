# Class to handle 'smartos up' command
class Up < SmartOS::Generators::Command
  def self.perform(args)
    puts "Up!!!! #{args}"
  end
end
