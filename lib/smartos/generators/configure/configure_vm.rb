module SmartOS
  module Configure
    module ConfigureVm

      def configure_virtual_machine(gz_info)

        @res ||= get_available_images(gz_info)

        chosen              = gather_dataset
        machine_alias       = gather_alias
        hostname            = gather_vm_hostname(machine_alias, gz_info.hostname)
        pvn_ip              = gather_pvn_ip(gz_info)
        internet_facing_ip  = gather_internet_facing_ip(gz_info)
        memory_cap          = gather_memory_cap
        disk_cap            = gather_disk_cap
        cpu_cores           = gather_cpu_cores
        copy_ssh_key        = gather_copy_ssh_key

        VmDefinition.new(
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

      # Asks the user to choose a dataset to use to create the VM. This can be any brand (Zone, KVM, LX ...).
      # It prioritizes thelatest base64 and standard64 SmartOS datasets (Zones), and Debian and CentOS datasets (KVM).
      # The user also has the choice to pick from any of the many other available datasets.
      # @return [Hash] Hash containing the manifest of the chosen image dataset.
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
            add_other_options(menu)      
          end
      end

      # Asks the user for an alias for the virtual machine. (e.g. web)
      # @return [String] String containing the users chosen alias for the virtual machine.
      def gather_alias
        machine_alias = ask("Enter an Alias for this machine: (e.g. web)") do |q|
          q.validate = /\A\w+\Z/
          q.responses[:not_valid] = "Please enter a valid alias."
        end
      end

      # Asks the user for a hostname for the virtual machine.
      # The default answer will be prepopulated with alias.gz_hostname. (e.g. web.example.com)
      # @return [String] String containing the users chosen hostname for the virtual machine.
      def gather_vm_hostname(machine_alias, gz_hostname)
        domain = PublicSuffix.parse(gz_hostname).domain
        hostname = ask("Enter a hostname for this machine:") do |q|
          q.default = "#{machine_alias}.#{domain}"
        end
      end

      # Asks the user to choose an IP for the PVN interface.
      # The default answer will be prepopulated with the next available IP from the PVN net
      # range the user chose when configuring the Global Zone. (e.g. 10.10.10.2)
      # @return [IPAddress] IPAddress containing the users chosen IP for the PVN interface.
      def gather_pvn_ip(gz_info)
        gather_ip("Please enter the PVN IP you want to use:", :get_next_free_pvn_ip, gz_info)
      end

      # Asks the user whether this machine needs an interface bound to the Internet and if so to
      # choose an IP for that interface.
      # The default answer will be prepopulated with the next available IP from the Internet net
      # range the user chose when configuring the Global Zone. (e.g. 153.32.32.122)
      # @return [IPAddress] IPAddress containing the users chosen IP for the Internet interface.
      def gather_internet_facing_ip(gz_info)
        if agree("Does this machine need an Internet facing IP address?"){ |q| q.default = 'no'}
          gather_ip("Please enter the internet facing IP you want to use:", :get_next_free_internet_facing_ip, gz_info)
        end
      end

      def gather_memory_cap
        memory_cap = ask("Maximum memory this machine should use?") do |q|
          q.validate = /\A\d+(mb|gb)\z/i
          q.default = '4GB'
          q.case = :up
        end
      end

      def gather_disk_cap
        disk_cap = ask("Maximum disk space this machine should use?")  do |q| 
          q.validate = /\A\d+(mb|gb)\z/i
          q.default = '20GB'
          q.case = :up
        end
      end

      def gather_cpu_cores
        cpu_cores = ask("How many CPU cores should this machine use?", Integer) do |q|
          q.default = 1
        end
      end

      def gather_copy_ssh_key
        copy_ssh_key = agree("Do you want to copy over your public SSH key to allow passwordless login?") do |q| 
          q.default = 'yes'
        end
      end

      def get_available_images(gz_info)
        SmartOS::GlobalZone.connect(gz_info.gz_host) do
          imgadm!('avail -j')
        end
      end

      def latest_of_type(res, proc)
        res.select{|dataset| proc.call(dataset['manifest']['name']) }.first
      end

      def dataset_description(dataset, note = nil)
        d = dataset['manifest']
        "#{d['uuid']} #{'%23s' % d['name']}#{'%17s' % d['version']}#{'%10s' % d['os']} #{note.blue if note}"
      end

      def gather_ip(message, func, gz_info)
        loop do
          ip = IPAddress.parse(ask(message){ |q| q.default = send(func, gz_info)})
          return ip if ip.ipv4?
        end
      end

      def add_other_options(menu)
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
  end
end