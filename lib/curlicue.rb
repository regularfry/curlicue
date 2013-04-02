# encoding: utf-8

require 'curlicue/exchange'
require 'curlicue/server'


module Curlicue


  # Public: Get an Exchange object which stores its messages in `dir`.
  #
  # dir - a directory path where the queues will be persisted.
  #
  # Examples
  #
  #   Dir.mktmpdir do |dir|
  #     exchg = Curlicue.exchange( dir )
  #     exchg.push( "new-queue", {'a' => 'b'} )
  #     puts exchg.pull_json( "new-queue" )
  #   end
  #
  # Returns a Curlicue::Exchange object.
  def self.exchange( dir )
    Exchange.for_dir( dir )
  end


  # Public: Get a Rack app which serves the messages stored in
  # `exchange`.
  #
  # exchange - an Exchange instance, or anything else which responds
  #            to #pull_json.
  #
  # Examples
  #
  #   # in one process
  #
  #   require 'rack/handler/puma'
  #
  #   dir = Dir.mktmpdir
  #   exchange = Curlicue.exchange( dir )
  #   exchange.push( "new-queue", {'a' => 'b'} )
  #   app = Curlicue.server( exchange )
  #   
  #   Rack::Handler::Puma.run( app )
  #
  #   
  #   # elsewhere...
  #
  #   $ curl http://localhost:8080/queues/new-queue.json
  #   [{"cursor":1,"content":{"a":"b"}}]
  #
  # Returns a Curlicue::Server object
  def self.server( exchange )
    Server.new( exchange )
  end


end
