require 'slop'
require 'pry'
require 'colorize'
require "smartos/generators/version"
require "smartos/generators/command"
require "smartos/generators/exceptions"
Gem.find_files("smartos/generators/commands/**/*.rb").each { |path| require path }