require 'slop'
require 'pry'
require 'yaml'
require 'colorize'
require 'highline'
require 'ipaddress'
require 'public_suffix'
require 'terminal-table'
require 'smartos'
require 'smartos/generators/version'
require 'smartos/generators/extensions'
require 'smartos/generators/command'
require 'smartos/generators/exceptions'
require 'smartos/generators/definitions/gz_definition'
require 'smartos/generators/definitions/vm_definition'
require 'smartos/generators/configure/configure_gz'
require 'smartos/generators/configure/configure_vm'
Gem.find_files('smartos/generators/commands/**/*.rb').each { |path| require path }
