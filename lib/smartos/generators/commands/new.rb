class New < SmartOS::Generators::Command
  # Creates a new SmartOS infrastructure project.
  # Every Command must imnplement 'perform'.
  # @param args arguments to be parsed
  # @return [void]
  def perform(args)
    opts = Slop.parse!(args) do
      banner (<<-eos
      Usage:
        smartos new <name>

      Description:
        Creates a new SmartOS virtual infrastructure project.

        Asks some questions about the specifications of the machines you want to be created and the
        topology of your network and then creates configuration files and JSON machine definitions
        automatically from templates.

        This command can also help configure a VPN using OpenVPN and generate configuration files.

        You can then create this infrastructure with the 'smartos up' command.
      eos
      ).strip_indent

      on 'v', 'verbose', 'Enable verbose mode'
    end

    if args.size != 1
      puts opts
      exit
    end

    new_project(args.first)
  end

  # Creates a new SmartOS infrastructure project.
  # @param name [String] String containing a name for the project.
  # @return [void]
  def new_project(name)
    path = File.expand_path(name)
    if Dir.exist?(path)
      puts "#{path} already exists. Please choose a directory name that doesn't already exist.".red
      exit
    end

    system 'mkdir', '-p', path
    puts "Creating New SmartOS Infrastructure Project: #{name}".blue.bold
    puts "At path: #{path}".green

    zone = new_global_zone

    puts "\nYou have now configured your SmartOS virtual infrastructure. Inspect it, then run "\
         "'smartos up' to build it!".blue
  end

  # Creates a new SmartOS Global Zone definition
  # @return [void]
  def new_global_zone
    host_or_ip = info = nil

    loop do
      host_or_ip = ask "\nPlease enter the IP address or hostname of your SmartOS Global Zone:"

      info = SmartOS::GlobalZone.is_global_zone?(host_or_ip)
      break if info
      puts 'Not a valid SmartOS Global Zone hostname or IP address.'.red
    end

    puts "\nSuccessfully connected to Global Zone #{host_or_ip}".green
    puts "#{info}\n".green

    # Gather information
    hostname_to_set     = gather_hostname(host_or_ip)
    local_net_range     = gather_pvn_vlan_details
    internet_net_range  = gather_internet_vlan_details

    if agree "\nDo you want to create your Virtual Machine definitions now?"
      loop do
        configure_virtual_machine(host_or_ip)
        break unless agree "\nFinished configuring this VM. Add another?"
      end
    else
      puts "\nSkipping Machine definitions."
    end
  end

  # Asks the user to provide network details for their private virtual network.
  # @return [IPAddress] containing the IP/Subnet information the user provided.
  def gather_pvn_vlan_details
    loop do
      answer = ask\
        "\nPlease enter the IP range you'd like to set up your private virtual network in CIDR "\
        'notation (e.g. 10.0.0.1/24)'
      begin
        ip = IPAddress.parse(answer)
        if ip.prefix == 32
          puts "\nPlease enter a range. You entered a single IP address.".red
        else
          puts "\nConfiguring private virtual network as Address: #{ip.address} "\
          "- Netmask: #{ip.netmask}".green
          return ip
        end
      rescue
        puts "\nInvalid CIDR IP range.".red
      end
    end
  end

  # Asks the user to provide network details for their internet facing subnet.
  # @return [IPAddress] containing the IP/Subnet information the user provided.
  def gather_internet_vlan_details
    loop do
      answer = ask\
        "\nPlease enter the IP range you'd like to use for your Internet-facing Network in CIDR "\
        'notation (e.g. 158.251.218.81/29)'
      begin
        ip = IPAddress.parse(answer)
        if ip.prefix == 32
          puts "\nPlease enter a range. You entered a single IP address.".red
        else
          puts "\nConfiguring internet-facing network as Address: #{ip.address} - Netmask: "\
               "#{ip.netmask}".green
          return ip
        end
      rescue
        puts "\nInvalid CIDR IP range.".red
      end
    end
  end

  # Asks the user for a hostname and whether to set it when the GZ boots.
  # @param host_or_ip [String] String containing a hostname or IP address.
  # @return [String] String containing hostname to set on boot on the GZ or nil.
  def gather_hostname(host_or_ip)
    is_ip = !!IPAddr.new(host_or_ip) rescue false
    hostname_to_set = nil
    if is_ip
      hostname_to_set =
        ask 'Please enter the hostname for the Global Zone - this will be set on boot:'
    else
      hostname_to_set =
        agree("Do you wish to set the hostname to '#{host_or_ip}' on boot?") ?
          host_or_ip : nil
    end
  end

  def configure_virtual_machine(host)

    res = []
    SmartOS::GlobalZone.connect(host) do
      res = imgadm!('avail -j')
    end


    base64 = latest_of_type(res, ->(name){name == 'base64'})
    standard64 = latest_of_type(res, ->(name){name == 'standard64'})
    debian = latest_of_type(res, ->(name){/debian.*/.match(name)})
    centos = latest_of_type(res, ->(name){/centos.*/.match(name)})

    say "Please choose the dataset to base the VM on:"
    choose do |menu|
      menu.choice dataset_description(base64, '(Latest base64)')
      menu.choice dataset_description(standard64, '(Latest standard64)')
      menu.choice dataset_description(debian, '(Latest Debian)')
      menu.choice dataset_description(centos, '(Latest CentOS)')
      
      menu.choice "Choose from all #{res.length} Datasets" do
        choose do |menu|
          res.reverse_each do |dataset|
            menu.choice dataset_description(dataset)
          end
        end
      end

    end
  end

  private
  def dataset_description(dataset, note = nil)
    d = dataset['manifest']
    "#{d['uuid']} #{'%23s' % d['name']}#{'%17s' % d['version']}#{'%10s' % d['os']} #{note.blue if note}"
  end

  def latest_of_type(res, proc)
    res.select{|dataset| proc.call(dataset['manifest']['name']) }.first
  end
end


=begin

Available Datasets
-------------------
1) Latest base64 14.2.0 (Zone, Already Installed)
2) Latest standard64 14.2.0 (Zone)
3) Latest debian 20141001 (KVM)
4) Latest centos 20141001 (KVM)
5) List all 56 Datasets

Add option to change dataset source
=end











