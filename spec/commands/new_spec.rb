require 'spec_helper'

describe "'smartos new' command" do

  def new_global_zone_from_answers(answers)
    newCommand = New.new
    answers_io = StringIO.new(answers.join("\n"))
    answers_io.rewind
    newCommand.console = HighLine.new(answers_io, StringIO.new)
    @imgadm_get_data ||= JSON.parse(File.read('spec/fixtures/imgadm-get.json'))
    newCommand.instance_variable_set(:@res, @imgadm_get_data)
    newCommand.new_global_zone('SunOS gz.menu.directory 5.11 joyent_20140919T024804Z i86pc i386 i86pc')
  end

  it "should configure a single virtual machine correctly when accepting defaults" do    
    answers = [
      'gz.menu.directory',  # host or ip of global zone
      '',                   # hostname to set (defaults to gz.menu.directory)
      '10.0.0.1/24',        # pvn net range
      '158.251.218.81/29',  # internet net range
      '',                   # repository (defaults to datasets.at)
      '',                   # Define your machines now? (defaults to yes)
      '2',                  # dataset
      'db',                 # alias
      '',                   # hostname (default)
      '',                   # PVN IP
      '',                   # internet facing interface?
      '',                   # memory cap
      '',                   # disk cap
      '',                   # cpu cores
      '',                   # copy ssh key
      'no'                  # finished configuring. add another vm?
    ]

    result = new_global_zone_from_answers(answers)
    
    expect(result.gz_host).to eq('gz.menu.directory')
    expect(result.hostname).to eq('gz.menu.directory')
    expect(result.dataset_repository).to eq('https://datasets.at/')
    expect(result.pvn_net_range).to eq(IPAddress.parse('10.0.0.1/24'))
    expect(result.internet_net_range).to eq(IPAddress.parse('158.251.218.81/29'))
    expect(result.gz_pvn_ip).to eq(IPAddress.parse('10.0.0.1'))
    expect(result.gz_internet_ip).to eq(IPAddress.parse('158.251.218.81'))

    expect(result.vm_definitions.size).to eq(1)

    vmd = result.vm_definitions.first
    expect(vmd.dataset['uuid']).to eq('3f57ffe8-47da-11e4-aa8b-dfb50a06586a')
    expect(vmd.machine_alias).to eq('db')
    expect(vmd.hostname).to eq('db.menu.directory')
    expect(vmd.pvn_ip).to eq(IPAddress.parse('10.0.0.2'))
    expect(vmd.internet_facing_ip).to eq(nil)
    expect(vmd.memory_cap).to eq('2GB')
    expect(vmd.disk_cap).to eq('20GB')
    expect(vmd.cpu_cores).to eq(1)
    expect(vmd.copy_ssh_key).to eq(true)
  end

  xit "should configure a single virtual machine correctly when overriding defaults" do
    answers = [
      '144.76.94.208',          # host or ip of global zone
      'gz.monkey.com',          # hostname to set 
      '10.20.0.1/24',           # pvn net range
      '168.211.218.81/29',      # internet net range
      '2',                      # repository
      'yes',                    # Define your machines now? (defaults to yes)
      '2',                      # dataset
      'web',                    # alias
      'www.monkey.com',         # hostname
      '',                       # PVN IP
      'yes',                    # is this machine to be internet facing?
      '158.251.218.82',         # internet facing IP
      '3GB',                    # memory cap
      '30GB',                   # disk cap
      '2',                      # cpu cores
      'no',                     # copy ssh key
      'no'                      # finished configuring. add another vm?
    ]

    result = new_global_zone_from_answers(answers)

    expect(result).to eq(GlobalZoneDefinition.new(
        gz_host:            '144.76.94.208',
        hostname:           'gz.monkey.com',
        local_net_range:    IPAddress.parse('10.20.0.1/24'),
        internet_net_range: IPAddress.parse('168.211.218.81/29'),
        dataset_repository: 'https://images.joyent.com',
        vm_definitions:     [
          MachineDefinition.new(
            dataset: @imgadm_get_data.find{|x|x['manifest']['uuid'] == '3f57ffe8-47da-11e4-aa8b-dfb50a06586a'}['manifest'],
            hostname: 'www.monkey.com',
            machine_alias: 'web',
            memory_cap: '3GB',
            disk_cap: '30GB',
            cpu_cores: 2,
            copy_ssh_key: false,
            internet_facing_ip: IPAddress.parse('158.251.218.82'),
            pvn_ip: IPAddress.parse('10.20.0.1')
          )]
    ))
  end


  xit "should configure several virtual machines correctly with the expected results" do
    answers = [
      '144.76.94.208',          # host or ip of global zone
      'gz.monkey.com',          # hostname to set 
      '10.20.0.1/24',           # pvn net range
      '168.211.218.81/29',      # internet net range
      '2',                      # repository
      'yes',                    # Define your machines now? (defaults to yes)

      '5',                      # dataset (show more)
      '274',                    # dataset
      'web',                    # alias
      'www.monkey.com',         # hostname
      'yes',                    # is this machine to be internet facing?
      '',                       # PVN IP
      '',                       # internet facing IP
      '3GB',                    # memory cap
      '30GB',                   # disk cap
      '2',                      # cpu cores
      'no',                     # copy ssh key
      'yes',                    # finished configuring. add another vm?

      '1',                      # dataset
      'redis',                  # alias
      '',                       # hostname
      'yes',                    # is this machine to be internet facing?
      '',                       # PVN IP
      '',                       # internet facing IP
      '2GB',                    # memory cap
      '20GB',                   # disk cap
      '1',                      # cpu cores
      'no',                     # copy ssh key
      'yes',                    # finished configuring. add another vm?

      '1',                      # dataset
      'db',                     # alias
      '',                       # hostname
      'yes',                    # is this machine to be internet facing?
      '',                       # PVN IP
      '',                       # internet facing IP
      '8GB',                    # memory cap
      '50GB',                   # disk cap
      '1',                      # cpu cores
      'no',                     # copy ssh key
      'no',                     # finished configuring. add another vm?
    ]

    result = new_global_zone_from_answers(answers)

    expect(result).to eq(GlobalZoneDefinition.new(
        gz_host:            '144.76.94.208',
        hostname:           'gz.monkey.com',
        pvn_net_range:      IPAddress.parse('10.20.0.1/24'),
        internet_net_range: IPAddress.parse('168.211.218.81/29'),
        dataset_repository: 'https://images.joyent.com',
        vm_definitions:     [
          MachineDefinition.new(
            dataset: @imgadm_get_data.reverse[273]['manifest'],
            hostname: 'www.monkey.com',
            machine_alias: 'web',
            memory_cap: '3GB',
            disk_cap: '30GB',
            cpu_cores: 2,
            copy_ssh_key: false,
            internet_facing_ip: IPAddress.parse('168.211.218.82'),
            pvn_ip: IPAddress.parse('10.20.0.1')
          ),
          MachineDefinition.new(
            dataset: @imgadm_get_data.find{|x|x['manifest']['uuid'] == 'd34c301e-10c3-11e4-9b79-5f67ca448df0'}['manifest'],
            hostname: 'redis.monkey.com',
            machine_alias: 'redis',
            memory_cap: '2GB',
            disk_cap: '20GB',
            cpu_cores: 1,
            copy_ssh_key: false,
            internet_facing_ip: IPAddress.parse('168.211.218.83'),
            pvn_ip: IPAddress.parse('10.20.0.2')
          ),
          MachineDefinition.new(
            dataset: @imgadm_get_data.find{|x|x['manifest']['uuid'] == 'd34c301e-10c3-11e4-9b79-5f67ca448df0'}['manifest'],
            hostname: 'db.monkey.com',
            machine_alias: 'db',
            memory_cap: '8GB',
            disk_cap: '50GB',
            cpu_cores: 1,
            copy_ssh_key: false,
            internet_facing_ip: IPAddress.parse('168.211.218.84'),
            pvn_ip: IPAddress.parse('10.20.0.3')
          )
        ]
    ))
  end

end