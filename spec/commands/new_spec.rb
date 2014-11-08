require 'spec_helper'

describe "'smartos new' command" do

  def new_global_zone_from_answers(answers)
    newCommand = New.new
    stdin_io = StringIO.new(answers.join("\n"))
    stdout_io = StringIO.new
    newCommand.console = HighLine.new(stdin_io, stdout_io)
    @imgadm_get_data ||= JSON.parse(File.read('spec/fixtures/imgadm-get.json'))
    # Inject the mocks to bypass network activity
    newCommand.instance_variable_set(:@res, @imgadm_get_data)
    newCommand.instance_variable_set(:@gz_uname_info, 'SunOS gz.menu.directory 5.11')
    # Run the command
    result = newCommand.perform(['gz-test'])
    # stdout_io.rewind
    # stdout = stdout_io.to_a.select { |x|!x.strip.empty? }
    # puts stdout
    # Extract the result
    newCommand.instance_variable_get(:@gz_info)
  end

  it 'should exit when called with incorrect args' do
    newCommand = New.new
    expect { newCommand.perform(['asdasd','sdfsdf']) }.to raise_error
  end

  it 'should exit when called with a dir path that already exists' do
    newCommand = New.new
    expect { newCommand.perform(['.']) }.to raise_error
  end

  it 'should configure a single virtual machine correctly when accepting defaults' do
    answers = [
      'gz.menu.directory',  # host or ip of global zone
      '',                   # hostname to set (defaults to gz.menu.directory)
      '10.0.0.1/24',        # pvn net range
      '158.251.218.81/29',  # internet net range
      '',                   # repository (defaults to datasets.at)
      '',                   # Define your machines now? (defaults to yes)

      '2',                  # dataset
      'db',                 # alias
      '',                   # hostname (defaults to db.menu.directory)
      '',                   # PVN IP (defaults to 10.0.0.2)
      '',                   # internet facing interface? (defaults to no)
      '',                   # memory cap (defaults to 2GB)
      '',                   # disk cap (defaults to 20GB)
      '',                   # cpu cores (defaults to 1)
      '',                   # copy ssh key (defaults to yes)
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

  it 'should configure a single virtual machine correctly when overriding defaults' do
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
      '10.20.0.3',              # PVN IP
      'yes',                    # is this machine to be internet facing?
      '',                       # internet facing IP
      '3GB',                    # memory cap
      '30GB',                   # disk cap
      '2',                      # cpu cores
      'no',                     # copy ssh key
      'no'                      # finished configuring. add another vm?
    ]

    result = new_global_zone_from_answers(answers)

    expect(result.gz_host).to eq('144.76.94.208')
    expect(result.hostname).to eq('gz.monkey.com')
    expect(result.dataset_repository).to eq('https://images.joyent.com')
    expect(result.pvn_net_range).to eq(IPAddress.parse('10.20.0.1/24'))
    expect(result.internet_net_range).to eq(IPAddress.parse('168.211.218.81/29'))
    expect(result.gz_pvn_ip).to eq(IPAddress.parse('10.20.0.1'))
    expect(result.gz_internet_ip).to eq(IPAddress.parse('168.211.218.81'))

    expect(result.vm_definitions.size).to eq(1)

    vmd = result.vm_definitions.first
    expect(vmd.dataset['uuid']).to eq('3f57ffe8-47da-11e4-aa8b-dfb50a06586a')
    expect(vmd.machine_alias).to eq('web')
    expect(vmd.hostname).to eq('www.monkey.com')
    expect(vmd.pvn_ip).to eq(IPAddress.parse('10.20.0.3'))
    expect(vmd.internet_facing_ip).to eq(IPAddress.parse('168.211.218.82'))
    expect(vmd.memory_cap).to eq('3GB')
    expect(vmd.disk_cap).to eq('30GB')
    expect(vmd.cpu_cores).to eq(2)
    expect(vmd.copy_ssh_key).to eq(false)

  end

  it 'should configure several virtual machines correctly with the expected results' do
    answers = [
      '144.76.94.208',          # host or ip of global zone
      'gz.monkey.com',          # hostname to set
      '10.20.0.1/24',           # pvn net range
      '168.211.218.81/29',      # internet net range
      '2',                      # repository
      'yes',                    # Define your machines now?

      '5',                      # dataset (show more)
      '274',                    # dataset
      'web',                    # alias
      'www.monkey.com',         # hostname
      '',                       # PVN IP (default to 10.20.0.2)
      'yes',                    # is this machine to be internet facing?
      '',                       # internet facing IP (default to 168.211.218.82)
      '3GB',                    # memory cap
      '30GB',                   # disk cap
      '2',                      # cpu cores
      'no',                     # copy ssh key
      'yes',                    # finished configuring. add another vm
       
      '1',                      # dataset
      'redis',                  # alias
      '',                       # hostname (default to redis.monkey.com)
      '',                       # PVN IP (default to 10.20.0.3)
      'yes',                    # is this machine to be internet facing?
      '',                       # internet facing IP (default to 168.211.218.83)
      '2GB',                    # memory cap
      '20GB',                   # disk cap
      '1',                      # cpu cores
      'no',                     # copy ssh key
      'yes',                    # finished configuring. add another vm?

      '1',                      # dataset
      'db',                     # alias
      '',                       # hostname (default to db.monkey.com)
      '',                       # PVN IP (default to 10.20.0.4)
      'yes',                    # is this machine to be internet facing?
      '',                       # internet facing IP (default to 168.211.218.84)
      '8GB',                    # memory cap
      '50GB',                   # disk cap
      '1',                      # cpu cores
      'no',                     # copy ssh key
      'no'                      # finished configuring. add another vm?
    ]

    result = new_global_zone_from_answers(answers)

    expect(result.gz_host).to eq('144.76.94.208')
    expect(result.hostname).to eq('gz.monkey.com')
    expect(result.dataset_repository).to eq('https://images.joyent.com')
    expect(result.pvn_net_range).to eq(IPAddress.parse('10.20.0.1/24'))
    expect(result.internet_net_range).to eq(IPAddress.parse('168.211.218.81/29'))
    expect(result.gz_pvn_ip).to eq(IPAddress.parse('10.20.0.1'))
    expect(result.gz_internet_ip).to eq(IPAddress.parse('168.211.218.81'))

    expect(result.vm_definitions.size).to eq(3)

    vmd = result.vm_definitions[0]
    expect(vmd.dataset['uuid']).to eq('46ca6534-53d5-11e4-8fc3-1384eeb2f1c3')
    expect(vmd.machine_alias).to eq('web')
    expect(vmd.hostname).to eq('www.monkey.com')
    expect(vmd.pvn_ip).to eq(IPAddress.parse('10.20.0.2'))
    expect(vmd.internet_facing_ip).to eq(IPAddress.parse('168.211.218.82'))
    expect(vmd.memory_cap).to eq('3GB')
    expect(vmd.disk_cap).to eq('30GB')
    expect(vmd.cpu_cores).to eq(2)
    expect(vmd.copy_ssh_key).to eq(false)

    vmd = result.vm_definitions[1]
    expect(vmd.dataset['uuid']).to eq('d34c301e-10c3-11e4-9b79-5f67ca448df0')
    expect(vmd.machine_alias).to eq('redis')
    expect(vmd.hostname).to eq('redis.monkey.com')
    expect(vmd.pvn_ip).to eq(IPAddress.parse('10.20.0.3'))
    expect(vmd.internet_facing_ip).to eq(IPAddress.parse('168.211.218.83'))
    expect(vmd.memory_cap).to eq('2GB')
    expect(vmd.disk_cap).to eq('20GB')
    expect(vmd.cpu_cores).to eq(1)
    expect(vmd.copy_ssh_key).to eq(false)

    vmd = result.vm_definitions[2]
    expect(vmd.dataset['uuid']).to eq('d34c301e-10c3-11e4-9b79-5f67ca448df0')
    expect(vmd.machine_alias).to eq('db')
    expect(vmd.hostname).to eq('db.monkey.com')
    expect(vmd.pvn_ip).to eq(IPAddress.parse('10.20.0.4'))
    expect(vmd.internet_facing_ip).to eq(IPAddress.parse('168.211.218.84'))
    expect(vmd.memory_cap).to eq('8GB')
    expect(vmd.disk_cap).to eq('50GB')
    expect(vmd.cpu_cores).to eq(1)
    expect(vmd.copy_ssh_key).to eq(false)
  end

end
