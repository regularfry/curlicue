# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)
 
require 'curlicue/version'
 
Gem::Specification.new do |s|
  s.name        = "curlicue"
  s.version     = Curlicue::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Alex Young"]
  s.email       = ["alex@blackkettle.org"]
  s.homepage    = "https://github.com/regularfry/curlicue"
  s.summary     = "A very simple message queue"
  s.description = "Curlicue publishes messages to a pull-only HTTP interface."
 
  s.required_rubygems_version = ">= 1.3.6"
 
  s.add_dependency( "amalgalite", "~>1.3.0" )
  s.add_dependency( "sinatra", "~>1.4.2" )
  s.add_dependency( "json" )
  s.add_dependency( "rack", "~>1.5.2" )

  s.add_development_dependency( "rack-test", "~>0.6.2" )
 
  s.files        = Dir.glob("lib/**/*") + %w(LICENSE.txt README.md)
  s.require_path = 'lib'
end
