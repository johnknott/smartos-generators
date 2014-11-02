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
      '10.0.0.1/24',        # local net range
      '158.251.218.81/29',  # internet net range
      '',                   # repository (defaults to datasets.at)
      '',                   # Define your machines now? (defaults to yes)
      '2',                  # dataset
      'db',                 # alias
      '',                   # hostname (default)
      '',                   # internet facing interface?
      '',                   # memory cap
      '',                   # disk cap
      '',                   # cpu cores
      '',                   # copy ssh key
      'no'                  # finished configuring. add another vm?
    ]

    result = new_global_zone_from_answers(answers)
    
    expect(
      OpenStruct.new(
        gz_host:            'gz.menu.directory',
        hostname:           'gz.menu.directory',
        local_net_range:    IPAddress.parse('10.0.0.1/24'),
        internet_net_range: IPAddress.parse('158.251.218.81/29'),
        dataset_repository: 'https://datasets.at/',
        vm_definitions:     [
          OpenStruct.new(
            dataset: @imgadm_get_data.find{|x|x['manifest']['uuid'] == '3f57ffe8-47da-11e4-aa8b-dfb50a06586a'}['manifest'],
            hostname: 'db.menu.directory',
            machine_alias: 'db',
            memory_cap: '2GB',
            disk_cap: '20GB',
            cpu_cores: 1,
            copy_ssh_key: true
          )]
    )).to eq(result)
  end

  it "should configure a single virtual machine correctly when overriding defaults" do
    answers = [
      '144.76.94.208',          # host or ip of global zone
      'gz.monkey.com',          # hostname to set 
      '10.20.0.1/24',           # local net range
      '168.211.218.81/29',      # internet net range
      '2',                      # repository
      'yes',                    # Define your machines now? (defaults to yes)
      '2',                      # dataset
      'web',                    # alias
      'www.monkey.com',         # hostname
      'yes',                    # is this machine to be internet facing?
      '158.251.218.82',         # internet facing IP
      '3GB',                    # memory cap
      '30GB',                   # disk cap
      '2',                      # cpu cores
      'no',                     # copy ssh key
      'no'                      # finished configuring. add another vm?
    ]

    result = new_global_zone_from_answers(answers)

    expect(
      OpenStruct.new(
        gz_host:            '144.76.94.208',
        hostname:           'gz.monkey.com',
        local_net_range:    IPAddress.parse('10.20.0.1/24'),
        internet_net_range: IPAddress.parse('168.211.218.81/29'),
        dataset_repository: 'https://images.joyent.com',
        vm_definitions:     [
          OpenStruct.new(
            dataset: @imgadm_get_data.find{|x|x['manifest']['uuid'] == '3f57ffe8-47da-11e4-aa8b-dfb50a06586a'}['manifest'],
            hostname: 'www.monkey.com',
            machine_alias: 'web',
            memory_cap: '3GB',
            disk_cap: '30GB',
            cpu_cores: 2,
            copy_ssh_key: false
          )]
    )).to eq(result)
  end

end