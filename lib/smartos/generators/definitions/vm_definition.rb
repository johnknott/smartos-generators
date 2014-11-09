# Class that represents a SmartOS VM (Either Zone or KVM)
class VmDefinition
  # @return [Hash] Manifest describing the dataset. Contains UUID, version, description, type (Zone, KVM...) etc.
  attr_accessor :dataset
  # @return [String] Alias to use for this machine. (e.g. web)
  attr_accessor :machine_alias
  # @return [String] Hostname to set for this machine. (e.g. web.example.com)
  attr_accessor :hostname
  # @return [String] Memory Cap for this machine. Can be overprovisioned for Zones, not so for KVM. (e.g. 4GB)
  attr_accessor :memory_cap
  # @return [String] Disk Cap for this machine. Can be overprovisioned. (e.g. 20GB)
  attr_accessor :disk_cap
  # @return [Integer] Number of cores to use for this VM.
  attr_accessor :cpu_cores
  # @return [Boolean] Whether to copy over the deploying machines SSH public key to this machine/
  attr_accessor :copy_ssh_key
  # @return [String] IP Address of the Internet facing Interface on this machine, or nil if there is not one.
  attr_accessor :internet_facing_ip
  # @return [String] IP Address of the PVN Interface on this machine
  attr_accessor :pvn_ip

  # Constructor for a Global Zone definition.
  # @param dataset [Hash] Manifest describing the dataset. Contains UUID, version, description, type (Zone, KVM...) etc.
  # @param machine_alias [String] Alias to use for this machine. (e.g. web)
  # @param hostname [String] Hostname to set for this machine. (e.g. web.example.com)
  # @param internet_facing_ip [String] IP Address of the Internet facing Interface on this machine, or nil if there is not one.
  # @param pvn_ip [String] IP Address of the PVN Interface on this machine
  # @param memory_cap [String] Memory Cap for this machine. Can be overprovisioned for Zones, not so for KVM. (e.g. 4GB)
  # @param disk_cap [String] Disk Cap for this machine. Can be overprovisioned. (e.g. 20GB)
  # @param copy_ssh_key [Boolean] Whether to copy over the deploying machines SSH public key to this machine.
  def initialize(dataset, machine_alias, hostname, pvn_ip,
                internet_facing_ip: nil, memory_cap: nil, disk_cap: nil, cpu_cores: nil, copy_ssh_key: nil)
    # Loop through all parameters and set instance variables
    method(__method__).parameters.each{ |arg| eval("@#{arg[1]}=#{arg[1]}") }
  end

end