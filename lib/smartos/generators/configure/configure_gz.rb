module SmartOS
  module Configure
    module ConfigureGz

      # Creates a new SmartOS Global Zone definition
      # @return [void]
      def new_global_zone
        host_or_ip = gather_gz_hostname

        # Gather information
        gz_info = GzDefinition.new(
          host_or_ip,
          gather_hostname(host_or_ip),
          gather_pvn_vlan_details,
          gather_internet_vlan_details,
          gather_repository)

        gz_info.print_gz_summary

        gz_info
      end

      def print_hypervisor_summary(gz_info)
        puts "\nSummary of your virtual infrastructure:\n".blue.bold
        gz_info.print_gz_summary
        print_vm_summaries(gz_info)
      end

      def print_vm_summaries(gz_info)
        puts "Machine Definitions".blue
        table = Terminal::Table.new do |t|
          t.headings = ['Alias', 'Hostname', 'Dataset', 'Version', 'Type', 'VLAN IP', 'Internet IP', 'Cores', 'Mem', 'Disk']
          gz_info.vm_definitions.each do |vm|
            t << vm_summary_row(vm)
          end
        end
        puts table
      end

      def vm_summary_row(vm)
        [
          vm.machine_alias,
          vm.hostname,
          vm.dataset['name'],
          vm.dataset['version'],
          vm.dataset['os'],
          vm.pvn_ip,
          vm.internet_facing_ip || 'None',
          vm.cpu_cores,
          vm.memory_cap, 
          vm.disk_cap
        ]
      end

      def gather_gz_hostname
        host_or_ip = nil
        loop do
          host_or_ip = ask "Please enter the IP address or hostname of your SmartOS Global Zone:"

          @gz_uname_info ||= SmartOS::GlobalZone.is_global_zone?(host_or_ip)
          break if @gz_uname_info
          say 'Not a valid SmartOS Global Zone hostname or IP address.'.red
        end

        say "Successfully connected to Global Zone #{host_or_ip}".green
        say "#{@gz_uname_info}".green
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
            "notation:"){ |q| q.default = '10.10.10.0/24'}
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
        gateway = gz_info.send(net_range).first.address
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

