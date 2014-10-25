class Console < SmartOS::Generators::Command
  def self.perform(args) 
    puts "Wizard!!!! #{args}"
  end
end