# -*- encoding: utf-8 -*-

lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'senedsa/version'
require 'senedsa/about'

Gem::Specification.new do |s|
  s.name                      = Senedsa::ME.to_s
  s.version                   = Senedsa::VERSION
  s.platform                  = Gem::Platform::RUBY
  s.authors                   = "Gerardo López-Fernádez"
  s.email                     = 'gerir@evernote.com'
  s.homepage                  = 'https://github.com/evernote/senedsa'
  s.summary                   = "Utility and library wrapper for Nagios send_nsca utility"
  s.description               = "Senedsa is a small utility and library wrapper for the Nagios send_nsca."
  s.license                   = "Apache License, Version 2.0"
  s.required_rubygems_version = ">= 1.3.5"

  s.files        = Dir['lib/**/*.rb'] + Dir['bin/*'] + %w(LICENSE README.md)
  s.executables  = %w(senedsa)
  s.require_path = 'lib'
end