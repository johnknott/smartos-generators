class New < SmartOS::Generators::Command
  # Creates a new SmartOS infrastructure project.
  # Every Command must implement 'perform'.
  # @param args arguments to be parsed
  # @return [void]
  def perform(args)
    opts = Slop.parse!(args) do
      banner strip_indent(<<-eos
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
      )

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

    #system 'mkdir', '-p', path
    #puts "Creating New SmartOS Infrastructure Project: #{name}".blue.bold
    #puts "At path: #{path}".green

    gz_info = new_global_zone

    puts

    table = Terminal::Table.new do |t|
      gz_info.vm_definitions.each do |vm|
        t << [vm.machine_alias, vm.hostname, vm.dataset['name'], vm.dataset['version'], vm.dataset['os']]
      end
    end

    puts table

    puts "\nYou have now configured your SmartOS virtual infrastructure. Inspect it, then run "\
         "'smartos up' to build it!".blue
  end

  # Creates a new SmartOS Global Zone definition
  # @return [void]
  def new_global_zone
    host_or_ip = info = nil

    loop do
      host_or_ip = @console.ask "\nPlease enter the IP address or hostname of your SmartOS Global Zone:"

      info = SmartOS::GlobalZone.is_global_zone?(host_or_ip)
      break if info
      puts 'Not a valid SmartOS Global Zone hostname or IP address.'.red
    end

    puts "\nSuccessfully connected to Global Zone #{host_or_ip}".green
    puts "#{info}\n".green

    # Gather information
    gz_info = OpenStruct.new(
      gz_host:            host_or_ip,
      hostname:           gather_hostname(host_or_ip),
      local_net_range:    gather_pvn_vlan_details,
      internet_net_range: gather_internet_vlan_details,
      dataset_repository: gather_repository,
      vm_definitions:     [])


    if agree "\nDo you want to create your Virtual Machine definitions now?"
      loop do
        gz_info.vm_definitions << configure_virtual_machine(gz_info)
        break unless agree_with_default("\nFinished configuring this VM. Add another?", 'yes')
      end
    else
      puts "\nSkipping Machine definitions."
    end

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
        @console.ask ('Please enter the hostname for the Global Zone - this will be set on boot:')
    else
      hostname_to_set =
        ask_with_default("Please enter the hostname for the Global Zone - this will be set on boot:", host_or_ip)
    end
  end

  # Asks the user to provide network details for their private virtual network.
  # @return [IPAddress] containing the IP/Subnet information the user provided.
  def gather_pvn_vlan_details
    loop do
      answer = ask_with_default(
        "Please enter the IP range you'd like to set up your private virtual network in CIDR "\
        "notation:", '10.0.0.20/24')
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
      answer = @console.ask\
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

  # Asks the user for a dataset repository to use. This will be set when when the GZ boots.
  # @return [String] String containing URL of the dataset repository to set.
  def gather_repository
    say "Please choose which dataset repository to use:" + " |https://datasets.at|".blue
    @console.choose do |menu|
      menu.default = 'https://datasets.at'
      menu.choice "https://datasets.at/"
      menu.choice "https://images.joyent.com"
    end
  end

  def configure_virtual_machine(gz_info)

    @res ||= get_available_images(gz_info)

    # Suggest a few likely machine images.
    # The most recent base64 and standard64 SmartOS datasets and the most recent Centos and Debian
    # KVM images. The user can also drill down and choose an image from the entire collection of
    # available datasets if they choose.

    base64 = latest_of_type(@res, ->(name){name == 'base64'})
    standard64 = latest_of_type(@res, ->(name){name == 'standard64'})
    debian = latest_of_type(@res, ->(name){/debian.*/.match(name)})
    centos = latest_of_type(@res, ->(name){/centos.*/.match(name)})

    chosen = nil
    @console.say "Please choose the dataset to base the VM on:"
     chosen = @console.choose do |menu|
      menu.select_by = :index
      menu.choice dataset_description(base64, '(Latest base64)') do base64 end
      menu.choice dataset_description(standard64, '(Latest standard64)') do standard64 end
      menu.choice dataset_description(debian, '(Latest debian)') do debian end
      menu.choice dataset_description(centos, '(Latest centos)') do centos end

      menu.choice "Choose from all #{@res.length} Datasets" do
        choose do |menu|
          @res.reverse_each do |dataset|
            menu.choice dataset_description(dataset) do dataset end
          end
        end
      end
    end

    # Gather an alias for this machine
    machine_alias = ask("Enter an Alias for this machine: i.e. web")

    # Gather a hostname for this machine. Suggest a likely value.
    domain = PublicSuffix.parse(gz_info.hostname).domain
    hostname = ask("Enter a hostname for this machine:") do |q|
      q.default = "#{machine_alias}.#{domain}"
    end

    # Does this machine need an internet facing IP?
    if agree("Does this machine need an Internet facing IP address?"){ |q| q.default = 'no'}
      ask("Please enter the internet facing IP you want to use:") do |q|
        q.default = gz_info.get_next_free_ip
      end
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

    num_cores = ask("How many CPU cores should this machine use?", Integer) do |q|
      q.default = 1
    end

    copy_ssh_key = agree("Do you want to copy over your public SSH key to allow passwordless login?") do |q| 
      q.default = 'yes'
    end

    OpenStruct.new(
      dataset: chosen['manifest'],
      machine_alias: machine_alias,
      hostname: hostname,
      memory_cap: memory_cap,
      disk_cap: disk_cap)
  end

  private
  def dataset_description(dataset, note = nil)
    d = dataset['manifest']
    "#{d['uuid']} #{'%23s' % d['name']}#{'%17s' % d['version']}#{'%10s' % d['os']} #{note.blue if note}"
  end

  def latest_of_type(res, proc)
    res.select{|dataset| proc.call(dataset['manifest']['name']) }.first
  end

  def ask(question, &block)
   @console.ask("\n" + question, &block)
  end

  def agree(question, &block)
   @console.agree("\n" + question, &block)
  end

  def ask_with_default(question, default)
    @console.ask("\n#{question}"){|q| q.default = default}
  end


  def get_available_images(gz_info)
    SmartOS::GlobalZone.connect(gz_info.gz_host) do
      imgadm!('avail -j')
    end
  end

end