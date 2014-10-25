require 'slop'
require 'pry'
require 'colorize'
require 'highline/import'
require 'smartos'
require "smartos/generators/version"
require "smartos/generators/command"
require "smartos/generators/exceptions"
Gem.find_files("smartos/generators/commands/**/*.rb").each { |path| require path }