class New < SmartOS::Generators::Command

  # Creates a new SmartOS infrastructure project.
  # Every Command must implement 'perform'.
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
      say opts
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
      say "#{path} already exists. Please choose a directory name that doesn't already exist.".red
      exit
    end

    gz_info = new_global_zone

    say table

    #system 'mkdir', '-p', path
    #say "Creating New SmartOS Infrastructure Project: #{name}".blue.bold
    #say "At path: #{path}".green

    say "You have now configured your SmartOS virtual infrastructure. Inspect it, then run "\
         "'smartos up' to build it!".blue
  end

  # Creates a new SmartOS Global Zone definition
  # @return [void]
  def new_global_zone(info = nil)
    host_or_ip = nil

    loop do
      host_or_ip = ask "Please enter the IP address or hostname of your SmartOS Global Zone:"

      info ||= SmartOS::GlobalZone.is_global_zone?(host_or_ip)
      break if info
      say 'Not a valid SmartOS Global Zone hostname or IP address.'.red
    end

    say "Successfully connected to Global Zone #{host_or_ip}".green
    say "#{info}".green

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

    gz_info
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

  def configure_virtual_machine(gz_info)

    @res ||= get_available_images(gz_info)

    chosen = gather_dataset

    # Gather an alias for this machine
    machine_alias = ask("Enter an Alias for this machine: (e.g. web)") do |q|
      q.validate = /\A\w+\Z/
      q.responses[:not_valid] = "Please enter a valid alias."
    end

    # Gather a hostname for this machine. Suggest a likely value.
    domain = PublicSuffix.parse(gz_info.hostname).domain
    hostname = ask("Enter a hostname for this machine:") do |q|
      q.default = "#{machine_alias}.#{domain}"
    end

    pvn_ip = IPAddress.parse(ask("Please enter the PVN IP you want to use:") do |q|
      q.default = get_next_free_pvn_ip(gz_info)
    end)

    # Does this machine need an internet facing IP?
    internet_facing_ip = nil
    if agree("Does this machine need an Internet facing IP address?"){ |q| q.default = 'no'}
      internet_facing_ip = IPAddress.parse(ask("Please enter the internet facing IP you want to use:") do |q|
        q.default = get_next_free_internet_facing_ip(gz_info)
      end)
    end

    memory_cap = ask("Maximum memory this machine should use?") do |q|
      q.validate = /\A\d+(mb|gb)\z/i
      q.default = '2GB'
      q.case = :up
    end

    disk_cap = ask("Maximum disk space this machine should use?")  do |q| 
      q.validate = /\A\d+(mb|gb)\z/i
      q.default = '20GB'
      q.case = :up
    end

    cpu_cores = ask("How many CPU cores should this machine use?", Integer) do |q|
      q.default = 1
    end

    copy_ssh_key = agree("Do you want to copy over your public SSH key to allow passwordless login?") do |q| 
      q.default = 'yes'
    end

    MachineDefinition.new(
      chosen['manifest'],
      machine_alias,
      hostname,
      pvn_ip,
      memory_cap: memory_cap,
      disk_cap: disk_cap,
      cpu_cores: cpu_cores,
      copy_ssh_key: copy_ssh_key,
      internet_facing_ip: internet_facing_ip)
  end

  private

  def gather_dataset

    # Suggest a few likely machine images.
    # The most recent base64 and standard64 SmartOS datasets and the most recent Centos and Debian
    # KVM images. The user can also drill down and choose an image from the entire collection of
    # available datasets if they choose.

    base64 = latest_of_type(@res, ->(name){name == 'base64'})
    standard64 = latest_of_type(@res, ->(name){name == 'standard64'})
    debian = latest_of_type(@res, ->(name){/debian.*/.match(name)})
    centos = latest_of_type(@res, ->(name){/centos.*/.match(name)})


    say "Please choose the dataset to base the VM on:"
    chosen = @console.choose do |menu|
      menu.select_by = :index
      menu.choice dataset_description(base64, '(Latest base64)') do base64 end
      menu.choice dataset_description(standard64, '(Latest standard64)') do standard64 end
      menu.choice dataset_description(debian, '(Latest debian)') do debian end
      menu.choice dataset_description(centos, '(Latest centos)') do centos end

      menu.choice "Choose from all #{@res.length} Datasets" do
        @console.choose do |menu|
          @res.reverse_each do |dataset|
            menu.select_by = :index
            menu.choice dataset_description(dataset) do dataset end
          end
        end
      end
    end
  end

  def dataset_description(dataset, note = nil)
    d = dataset['manifest']
    "#{d['uuid']} #{'%23s' % d['name']}#{'%17s' % d['version']}#{'%10s' % d['os']} #{note.blue if note}"
  end

  def latest_of_type(res, proc)
    res.select{|dataset| proc.call(dataset['manifest']['name']) }.first
  end

  def ask(question, type = nil, &block)
   @console.ask("\n#{question}", type, &block)
  end

  def agree(question, type = nil, &block)
   @console.agree("\n#{question}", type, &block)
  end

  def say(str)
   @console.say("#{str}")
  end

  def get_next_free_internet_facing_ip(gz_info)
    already_allocated = gz_info.vm_definitions.map{|x|x.internet_facing_ip.to_s}
    gateway = gz_info.internet_net_range.address
    gz_info.internet_net_range.each_host do |h|
      return h.to_s unless already_allocated.include?(h.to_s) || h.to_s == gateway
    end
    nil
  end

  def get_next_free_pvn_ip(gz_info)
    already_allocated = gz_info.vm_definitions.map{|x|x.pvn_ip.to_s}
    gateway = gz_info.pvn_net_range.address
    gz_info.pvn_net_range.each_host do |h|
      return h.to_s unless already_allocated.include?(h.to_s) || h.to_s == gateway
    end
    nil
  end

  def get_available_images(gz_info)
    SmartOS::GlobalZone.connect(gz_info.gz_host) do
      imgadm!('avail -j')
    end
  end

end