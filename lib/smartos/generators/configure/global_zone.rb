module SmartOS
  module Configure
    module GlobalZone

      # Creates a new SmartOS Global Zone definition
      # @return [void]
      def new_global_zone(info = nil)
        host_or_ip = gather_gz_hostname(info)

        # Gather information
        gz_info = GlobalZoneDefinition.new(
          host_or_ip,
          gather_hostname(host_or_ip),
          gather_pvn_vlan_details,
          gather_internet_vlan_details,
          gather_repository)

        if agree("Do you want to create your Virtual Machine definitions now?"){ |q| q.default = 'yes'}
          loop do
            gz_info.vm_definitions << configure_virtual_machine(gz_info)
            break unless agree("Finished configuring this VM. Add another?"){ |q| q.default = 'yes'}
          end
        else
          say "\nSkipping Machine definitions."
        end

        print_hypervisor_summary(gz_info)

        gz_info
      end

      def print_hypervisor_summary(gz_info)
        puts "Global Zone Information".blue
        puts "host: #{gz_info.gz_host}"
        puts "set hostname to: #{gz_info.hostname}"
        puts "pvn net range: #{gz_info.pvn_net_range}"
        puts "Machine Definitions".blue
        table = Terminal::Table.new do |t|
          t.headings = ['Alias', 'Hostname', 'Dataset', 'Version', 'Type', 'VLAN IP', 'Internet IP', 'Cores', 'Mem', 'Disk']
          gz_info.vm_definitions.each do |vm|
            t << [vm.machine_alias, vm.hostname, vm.dataset['name'], vm.dataset['version'], vm.dataset['os'],
                  vm.pvn_ip, vm.internet_facing_ip || 'None', vm.cpu_cores, vm.memory_cap, vm.disk_cap]
          end
        end

        puts table
      end

      def gather_gz_hostname(info)
        host_or_ip = nil
        loop do
          host_or_ip = ask "Please enter the IP address or hostname of your SmartOS Global Zone:"

          info ||= SmartOS::GlobalZone.is_global_zone?(host_or_ip)
          break if info
          say 'Not a valid SmartOS Global Zone hostname or IP address.'.red
        end

        say "Successfully connected to Global Zone #{host_or_ip}".green
        say "#{info}".green
        host_or_ip
      end

      # Asks the user for a hostname and whether to set it when the GZ boots.
      # @param host_or_ip [String] String containing a hostname or IP address.
      # @return [String] String containing hostname to set on boot on the GZ or nil.
      def gather_hostname(host_or_ip)
        is_ip = !!IPAddr.new(host_or_ip) rescue false
        hostname_to_set = nil
        if is_ip
          hostname_to_set =
            ask('Please enter the hostname for the Global Zone - this will be set on boot:')
        else
          hostname_to_set =
            ask("Please enter the hostname for the Global Zone - this will be set on boot:") {|q| q.default = host_or_ip}
        end
        say "Will set hostname to: #{hostname_to_set} on boot.".green

        hostname_to_set
      end

      # Asks the user to provide network details for their private virtual network.
      # @return [IPAddress] containing the IP/Subnet information the user provided.
      def gather_pvn_vlan_details
        loop do
          answer = ask(
            "Please enter the IP range you'd like to set up your private virtual network in CIDR "\
            "notation:"){ |q| q.default = '10.0.0.20/24'}
          begin
            ip = IPAddress.parse(answer)
            if ip.prefix == 32
              say "Please enter a range. You entered a single IP address.".red
            else
              say "Configuring private virtual network as Address: #{ip.address} "\
              "- Netmask: #{ip.netmask}".green
              return ip
            end
          rescue
            say "Invalid CIDR IP range.".red
          end
        end
      end

      # Asks the user to provide network details for their internet facing subnet.
      # @return [IPAddress] containing the IP/Subnet information the user provided.
      def gather_internet_vlan_details
        loop do
          answer = ask \
            "Please enter the IP range you'd like to use for your Internet-facing Network in CIDR "\
            'notation (e.g. 158.251.218.81/29)'
          begin
            ip = IPAddress.parse(answer)
            if ip.prefix == 32
              say "Please enter a range. You entered a single IP address.".red
            else
              say "Configuring internet-facing network as Address: #{ip.address} - Netmask: "\
                   "#{ip.netmask}".green
              return ip
            end
          rescue
            say "Invalid CIDR IP range.".red
          end
        end
      end

      # Asks the user for a dataset repository to use. This will be set when when the GZ boots.
      # @return [String] String containing URL of the dataset repository to set.
      def gather_repository
        say "\nPlease choose which dataset repository to use:" + " |https://datasets.at|"
        chosen = @console.choose do |menu|
          menu.default = 'https://datasets.at'
          menu.choice "https://datasets.at/"
          menu.choice "https://images.joyent.com"
        end
        say "#{chosen} will be used as your dataset repository.".green
        chosen
      end

      def get_next_free_ip(gz_info, net_range, ip)
        already_allocated = gz_info.vm_definitions.map{|x|x.send(ip).to_s}
        gateway = gz_info.send(net_range).address
        gz_info.send(net_range).each_host do |h|
          return h.to_s unless already_allocated.include?(h.to_s) || h.to_s == gateway
        end
        nil
      end

      def get_next_free_internet_facing_ip(gz_info)
        get_next_free_ip(gz_info, :internet_net_range, :internet_facing_ip)
      end

      def get_next_free_pvn_ip(gz_info)
        get_next_free_ip(gz_info, :pvn_net_range, :pvn_ip)
      end

    end
  end
end

