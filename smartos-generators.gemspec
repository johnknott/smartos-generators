lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'smartos/generators/version'

Gem::Specification.new do |spec|
  spec.name          = 'smartos-generators'
  spec.version       = SmartOS::Generators::VERSION
  spec.authors       = ['John Knott']
  spec.email         = ['john.knott@gmail.com']
  spec.summary       = 'A script that helps to create and maintain a SmartOS based infrastructure.'
  # spec.description   = %q{}
  spec.homepage      = 'https://github.com/johnknott/smartos-generators'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'highline-test'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency "codeclimate-test-reporter"
  spec.add_development_dependency "dotenv"

  spec.add_dependency 'slop'
  spec.add_dependency 'highline'
  spec.add_dependency 'colorize'
  spec.add_dependency 'ipaddress'
  spec.add_dependency 'public_suffix'
  spec.add_dependency 'terminal-table'
  spec.add_dependency 'smartos','~> 0.0.1.pre'
end
