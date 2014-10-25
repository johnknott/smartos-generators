class New < SmartOS::Generators::Command
  def perform(args) 
    opts = Slop.parse!(args) do
      banner Command.strip_heredoc <<-eos
      Usage:
        smartos new <name>

      Description:
        Creates a new SmartOS virtual infrastructure project.

        Asks some questions about the specifications of the machines you want
        to be created and the topology of your network and the and then creates
        configuration files and JSON machine definitions automatically from
        templates.

        This command can also help configure a VPN using OpenVPN and generate
        configuration files.

        You can then create this infrastructure with the 'smartos up' command.
      eos

      on 'v', 'verbose', 'Enable verbose mode'
    end

    if args.size != 1
      puts opts
      exit
    end

    new_project(args.first)

  end

  def new_project(name)
    path = File.expand_path(name)
    if Dir.exists?(path)
      puts "#{path} already exists. Please choose a directory name that doesn't already exist.".red
      exit
    end      

    system 'mkdir', '-p', path
    puts "Creating New SmartOS Infrastructure Project: #{name}".green
    puts "At path: #{path}".green

    loop do
      new_global_zone  
      break unless agree("\nFinished configuring this Global Zone. Add another?")
    end

    puts "\nYou have now configured your SmartOS virtual infrastructure. Inspect it, then run 'smartos up' to build it!".blue
  end

  def new_global_zone
    host_or_ip = info = nil

    loop do
      host_or_ip = ask "\nPlease enter the IP address or hostname of your SmartOS Global Zone:"
      info = SmartOS::GlobalZone.is_global_zone?(host_or_ip)
      break if info
      puts "Not a valid SmartOS Global Zone hostname or IP address.".red
    end

    puts "\nSuccessfully connected to Global Zone #{host_or_ip}".green
    puts "#{info}\n".green

    # Gather information
    hostname_to_set = gather_hostname(host_or_ip)
    local_net_range = gather_pvn_vlan_details
    internet_net_range = gather_internet_vlan_details
  end

  def gather_pvn_vlan_details
    loop do
      answer = ask "\nPlease enter the IP range you'd like to set up your Private Virtual Network in CIDR notation (e.g. 10.0.0.1/24)"
      begin
        ip = IPAddress.parse(answer)
        if ip.prefix == 32
          puts "\nPlease enter a range. You entered a single IP address.".red
        else
          puts "\nConfiguring Private Virtual Network as Address: #{ip.address} - Netmask: #{ip.netmask}".green
          return ip
        end
      rescue
        puts "\nInvalid CIDR IP range.".red
      end
    end
  end

  def gather_internet_vlan_details
    loop do
      answer = ask "\nPlease enter the IP range you'd like to use for your Internet-facing Network in CIDR notation (e.g. 158.251.218.81/29)"
      begin
        ip = IPAddress.parse(answer)
        if ip.prefix == 32
          puts "\nPlease enter a range. You entered a single IP address.".red
        else
          puts "\nConfiguring internet-facing network as Address: #{ip.address} - Netmask: #{ip.netmask}".green
          return ip
        end
      rescue
        puts "\nInvalid CIDR IP range.".red
      end
    end
  end

  def gather_hostname(hostname)
    is_ip = !!IPAddr.new(hostname) rescue false
    hostname_to_set = nil
    if is_ip
      hostname_to_set  = ask "Please enter the hostname for the Global Zone - this will be set on boot:"
    else
      hostname_to_set  = agree("Do you wish to set the hostname to '#{hostname}' on boot?") ? hostname : nil
    end
  end
end