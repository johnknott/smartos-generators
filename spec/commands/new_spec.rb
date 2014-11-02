require 'spec_helper'

describe "'smartos new' command" do

  it "should configure a single virtual machine correctly when accepting defaults" do
    gz_info = OpenStruct.new(
      gz_host:            'gz.menu.directory',
      hostname:           'gz.menu.directory',
      local_net_range:    '10.0.0.1/24',
      internet_net_range: '158.251.218.81/29',
      dataset_repository: 'https://datasets.at/',
      vm_definitions:     [])

    newCommand = New.new
    
    answers = [
      '2',      # dataset
      'db',     # alias
      '',       # hostname (default)
      '',       # internet facing interface?
      '',       # memory cap
      '',       # disk cap
      '',       # cpu cores
      '',       # copy ssh key
      ''
    ].join("\n")
    answer = StringIO.new(answers)
    answer.rewind

    newCommand.console = HighLine.new(answer, StringIO.new)
    imgadm_get_data = JSON.parse(File.read('spec/fixtures/imgadm-get.json'))
    newCommand.instance_variable_set(:@res, imgadm_get_data)
    result = newCommand.configure_virtual_machine(gz_info)

    expect(OpenStruct.new(
      dataset: imgadm_get_data.find{|x|x['manifest']['uuid'] == '3f57ffe8-47da-11e4-aa8b-dfb50a06586a'}['manifest'],
      hostname: 'db.menu.directory',
      machine_alias: 'db',
      memory_cap: '2GB',
      disk_cap: '20GB',
      cpu_cores: 1,
      copy_ssh_key: true
    )).to eq(result)
  end

  it "should configure a single virtual machine correctly when overriding defaults" do
    gz_info = OpenStruct.new(
      gz_host:            'gz.menu.directory',
      hostname:           'gz.menu.directory',
      local_net_range:    '10.0.0.1/24',
      internet_net_range: '158.251.218.81/29',
      dataset_repository: 'https://datasets.at/',
      vm_definitions:     [])

    newCommand = New.new
    
    answers = [
      '2',                      # dataset
      'web',                    # alias
      'www.monkey.com',         # hostname
      'no',                     # internet facing interface?
      '3GB',                    # memory cap
      '30GB',                   # disk cap
      '2',                      # cpu cores
      'no',                     # copy ssh key
      ''
    ].join("\n")
    answer = StringIO.new(answers)
    answer.rewind

    newCommand.console = HighLine.new(answer, StringIO.new)
    imgadm_get_data = JSON.parse(File.read('spec/fixtures/imgadm-get.json'))
    newCommand.instance_variable_set(:@res, imgadm_get_data)
    result = newCommand.configure_virtual_machine(gz_info)

    expect(OpenStruct.new(
      dataset: imgadm_get_data.find{|x|x['manifest']['uuid'] == '3f57ffe8-47da-11e4-aa8b-dfb50a06586a'}['manifest'],
      hostname: 'www.monkey.com',
      machine_alias: 'web',
      memory_cap: '3GB',
      disk_cap: '30GB',
      cpu_cores: 2,
      copy_ssh_key: false
    )).to eq(result)
  end

end