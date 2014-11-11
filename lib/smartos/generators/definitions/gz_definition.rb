# Class that represents a SmartOS Global Zone
class GzDefinition
  # @return [String] Hostname of IP address used to connect to the Global Zone.
  attr_accessor :gz_host
  # @return [String] Hostname to set when the Global Zone boots, or nil if it not to be set.
  attr_accessor :hostname
  # @return [IPAddress] IP range to use for the Private Virtual Network (e.g. 10.10.10.0/24)
  attr_accessor :pvn_net_range
  # @return [IPAddress] IP range to use for the Internet facing Network (e.g. 153.242.100.97/29)
  attr_accessor :internet_net_range
  # @return [String] Dataset repository to use with imgadm.
  attr_accessor :dataset_repository
  # @return [String] IP address to use for the PVN interface.
  attr_accessor :gz_pvn_ip
  # @return [String] IP address to use for the Internet facing interface.
  attr_accessor :gz_internet_ip
  # @return [Array] Array of [VmDefinition] VM definitions describing each VM to be created.
  attr_accessor :vm_definitions 

  # Constructor for a Global Zone definition.
  # @param gz_host [String] Hostname of IP address used to connect to the Global Zone.
  # @param hostname [String] Hostname to set when the Global Zone boots, or nil if it not to be set.
  # @param pvn_net_range [IPAddress] IP range to use for the Private Virtual Network (e.g. 10.10.10.0/24)
  # @param internet_net_range [IPAddress] IP range to use for the Internet facing Network (e.g. 153.242.100.97/29)
  # @param dataset_repository [String] Dataset repository to use with imgadm.
  # @param vm_definitions [Array] Array of [VmDefinition] VM definitions describing each VM to be created.
  def initialize(gz_host, hostname, pvn_net_range, internet_net_range, dataset_repository, vm_definitions: [])
    # Loop through all parameters and set instance variables
    method(__method__).parameters.each{ |arg| eval("@#{arg[1]}=#{arg[1]}") }

    # Set the IP on the PVN interface to be the first one available from the PVN range
    @gz_pvn_ip = IPAddress.parse(@pvn_net_range.first.address)
    # Set the IP on the Internet interface to be the first one available from the Internet range
    @gz_internet_ip = IPAddress.parse(@internet_net_range.first.address)
  end

  def print_gz_summary
    puts "Global Zone Information".blue
    table = Terminal::Table.new do |t|
      t << ['Host:', gz_host]
      t << ['Set hostname to:', hostname]
      t << ['PVN interface info:', "IP: #{gz_pvn_ip} Range: #{pvn_net_range}/#{pvn_net_range.prefix}"]
      t << ['Internet interface info:', "IP: #{gz_internet_ip} Range:  #{internet_net_range}/#{internet_net_range.prefix}"]
    end
    puts table
  end

  def serialize(path)
    FileUtils.mkdir_p path 
    puts "Creating New SmartOS Infrastructure Project: #{path}".blue.bold
    binding.pry
  end

  def deserialize
  end

end