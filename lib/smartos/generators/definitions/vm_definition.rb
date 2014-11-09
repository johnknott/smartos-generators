# Class that represents a SmartOS VM (Either Zone or KVM)
class VmDefinition
  attr_accessor :dataset, :machine_alias, :hostname, :memory_cap, :disk_cap, :cpu_cores, :copy_ssh_key,
                :internet_facing_ip, :pvn_ip

  def initialize(dataset, machine_alias, hostname, pvn_ip,
                internet_facing_ip: nil, memory_cap: nil, disk_cap: nil, cpu_cores: nil, copy_ssh_key: nil)

    method(__method__).parameters.each{ |arg| eval("@#{arg[1]}=#{arg[1]}") }
  end

end