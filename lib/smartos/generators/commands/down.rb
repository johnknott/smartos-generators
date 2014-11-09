# Class to handle 'smartos down' command
class Down < SmartOS::Generators::Command
  def self.perform(args)
    puts "Down!!!! #{args}"
  end
end
