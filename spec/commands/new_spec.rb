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
end