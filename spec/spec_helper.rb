require 'dotenv'
Dotenv.load
require "codeclimate-test-reporter"
CodeClimate::TestReporter.start
require 'bundler/setup'
Bundler.setup

require 'smartos'
require 'highline/test'
require 'rspec/expectations'
require 'fakefs/safe'
require_relative '../lib/smartos/generators'

RSpec.configure do |_config|
end
