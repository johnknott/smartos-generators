require 'yaml'
require 'bundler/gem_tasks'
require 'yardstick/rake/measurement'

Yardstick::Rake::Measurement.new(:yardstick_measure, YAML.load_file('config/yardstick.yml')) do |measurement|
  measurement.output = 'measurement/report.txt'
end