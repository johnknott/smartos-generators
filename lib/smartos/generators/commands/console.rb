# Class to handle 'smartos console' command
class Console < SmartOS::Generators::Command
  def self.perform(args)
    puts "Console!!!! #{args}"
  end
end
