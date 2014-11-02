require 'spec_helper'

describe "'smartos new' command" do
  it 'agree_with_default - answer should overwrite default' do
    newCommand = New.new
    answer = StringIO.new("Yes\n")
    newCommand.console = HighLine.new(answer)
    result = newCommand.send(:agree_with_default, 'Do you agree?', 'no')
    expect(result).to be_true
  end

  it 'agree_with_default - default should be honoured' do
    newCommand = New.new
    answer = StringIO.new("\n")
    newCommand.console = HighLine.new(answer)
    result = newCommand.send(:agree_with_default, 'Do you agree?', 'no')
    expect(result).to be_false
  end

  it 'ask_with_default - answer should overwrite default' do
    newCommand = New.new
    answer = StringIO.new("Camembert\n")
    newCommand.console = HighLine.new(answer)
    result = newCommand.send(:ask_with_default, 'What is your favourite cheese?', 'Edam')
    expect(result).to eq 'Camembert'
  end

  it 'ask_with_default - default should be honoured' do
    newCommand = New.new
    answer = StringIO.new("\n")
    newCommand.console = HighLine.new(answer)
    result = newCommand.send(:ask_with_default, 'What is your favourite cheese?', 'Edam')
    expect(result).to eq 'Edam'
  end

  it "should configure a single virtual machine correctly" do
    gz_info = OpenStruct.new(
      gz_host:            'gz.menu.directory',
      hostname:           'gz.menu.directory',
      local_net_range:    '10.0.0.1/24',
      internet_net_range: '158.251.218.81/29',
      dataset_repository: 'https://datasets.at/',
      vm_definitions:     [])

    newCommand = New.new
    answer = StringIO.new("2\ndb\n\nno\n3gb\n30gb\n1\nno\n")
    answer.rewind
    newCommand.console = HighLine.new(answer, StringIO.new)
    imgadm_get_data = JSON.parse(File.read('spec/fixtures/imgadm-get.json'))
    newCommand.instance_variable_set(:@res, imgadm_get_data)
    result = newCommand.configure_virtual_machine(gz_info)

    expect(OpenStruct.new(
      dataset: imgadm_get_data.find{|x|x['manifest']['uuid'] == '3f57ffe8-47da-11e4-aa8b-dfb50a06586a'}['manifest'],
      hostname: 'db.menu.directory',
      machine_alias: 'db',
      memory_cap: '3GB',
      disk_cap: '30GB'
    )).to eq(result)
  end


end