class GlobalZoneDefinition
  attr_accessor :gz_host, :hostname, :pvn_net_range, :internet_net_range, :dataset_repository,
                :gz_pvn_ip, :gz_internet_ip, :vm_definitions 

  def initialize(gz_host, hostname, pvn_net_range, internet_net_range, dataset_repository, vm_definitions: [])

    @gz_host, @hostname, @pvn_net_range, @internet_net_range, @dataset_repository = 
      gz_host, hostname, pvn_net_range, internet_net_range, dataset_repository

    @gz_pvn_ip = IPAddress.parse(@pvn_net_range.address)
    @gz_internet_ip = IPAddress.parse(@internet_net_range.address)
    @vm_definitions = vm_definitions
  end

end