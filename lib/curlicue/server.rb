# encoding: utf-8

require 'sinatra/base'

module Curlicue

  # Public: A Rack app to serve an exchange.  Currently implemented as
  # a Sinatra app.
  class Server < Sinatra::Base

    set :sessions, false

    def initialize( exchange )
      @exchange = exchange
      super()
    end


    get "/queues/:name.json" do
      from = params[:from]
      limit = params[:limit]

      opts = {}
      opts[:from] = from.to_i if from # TODO: handle the .to_i exception here
      opts[:limit] = limit.to_i if limit

      # Strictly speaking, we don't need write access to the databases
      # for the server, but that's more API work than I want to do
      # right now
      @exchange.pull_json( params[:name], opts ) || 404
    end

  end


end # module Curlicue
