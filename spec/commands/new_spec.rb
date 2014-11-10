require 'spec_helper'

describe "'smartos new' command" do

  def new_global_zone_from_answers(answers)
    newCommand = New.new
    stdin_io = StringIO.new(answers.join("\n") + "\n")
    stdout_io = StringIO.new
    newCommand.console = HighLine.new(stdin_io, stdout_io)
    # Inject the mocks to bypass network activity
    newCommand.instance_variable_set(:@gz_uname_info, 'SunOS gz.menu.directory 5.11')
    # Run the command
    result = newCommand.perform(['gz-test'])
    # Extract the result
    newCommand.instance_variable_get(:@gz_info)
  end

  def puts_stdout(stdout_io)
    stdout_io.rewind
    puts stdout_io.to_a.select { |x|!x.strip.empty? }
  end

  it 'should configure a single virtual machine correctly when accepting defaults' do
    answers = [
      'gz.menu.directory',  # host or ip of global zone
      '',                   # hostname to set (defaults to gz.menu.directory)
      '10.0.0.1/24',        # pvn net range
      '158.251.218.81/29',  # internet net range
      ''                    # repository (defaults to datasets.at)
    ]

    result = new_global_zone_from_answers(answers)
    expect(result.gz_host).to eq('gz.menu.directory')
    expect(result.hostname).to eq('gz.menu.directory')
    expect(result.dataset_repository).to eq('https://datasets.at/')
    expect(result.pvn_net_range).to eq(IPAddress.parse('10.0.0.1/24'))
    expect(result.internet_net_range).to eq(IPAddress.parse('158.251.218.81/29'))
    expect(result.gz_pvn_ip).to eq(IPAddress.parse('10.0.0.1'))
    expect(result.gz_internet_ip).to eq(IPAddress.parse('158.251.218.81'))
  end

  it 'should configure a single virtual machine correctly when overriding defaults' do
    answers = [
      '144.76.94.208',          # host or ip of global zone
      'gz.monkey.com',          # hostname to set
      '10.20.0.1/24',           # pvn net range
      '168.211.218.81/29',      # internet net range
      '2'                       # repository
    ]

    result = new_global_zone_from_answers(answers)

    expect(result.gz_host).to eq('144.76.94.208')
    expect(result.hostname).to eq('gz.monkey.com')
    expect(result.dataset_repository).to eq('https://images.joyent.com')
    expect(result.pvn_net_range).to eq(IPAddress.parse('10.20.0.1/24'))
    expect(result.internet_net_range).to eq(IPAddress.parse('168.211.218.81/29'))
    expect(result.gz_pvn_ip).to eq(IPAddress.parse('10.20.0.1'))
    expect(result.gz_internet_ip).to eq(IPAddress.parse('168.211.218.81'))
  end

  it 'should exit when called with incorrect args' do
    newCommand = New.new
    expect { newCommand.perform(['asdasd','sdfsdf']) }.to raise_error
  end

  it 'should exit when called with a dir path that already exists' do
    newCommand = New.new
    expect { newCommand.perform(['.']) }.to raise_error
  end

end
