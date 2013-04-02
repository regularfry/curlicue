# encoding: utf-8

require 'test/unit'
require 'rack/test'

require 'test/curlicue/mem_qdb'
require 'curlicue/queue'
require 'curlicue/server'


module TestCurlicue

  class FakeExchange

    def initialize( queues )
      @queues = queues
    end

    def push( queue_name, *args )
      @queues[queue_name].push( *args )
    end

    def pull_json( queue_name, opts = {} )
      (queue = @queues[queue_name]) && queue.pull_json( opts )
    end

  end # class FakeExchange


  class TestServer < Test::Unit::TestCase

    include Rack::Test::Methods
    include Curlicue

    def setup
      super
      @name = "my-queue-name"
      @queue = Queue.new( MemQdb.new )
      @exchange = FakeExchange.new( @name => @queue )
      @app = Server.new( @exchange )
    end


    def app
      @app
    end
    

    def test_get_all
      @queue.push( {'a' => 'b'} )
      
      response = get "/queues/#{@name}.json"
      assert list = JSON.parse( response.body )
      assert_equal 1, list.length
    end


    def test_get_from
      cursor = @queue.push( {'a' => 'b'} )
      @queue.push( {'c' => 'd'} )
      
      response = get "/queues/#{@name}.json?from=#{cursor}"
      assert list = JSON.parse( response.body )
      assert_equal 1, list.length
    end


    def test_get_limit
      cursor = @queue.push( {'a' => 'b'} )
      @queue.push( {'c' => 'd'} )
      
      response = get "/queues/#{@name}.json?limit=1"
      assert list = JSON.parse( response.body )
      assert_equal 1, list.length
    end

    def test_get_404s
      response = get "/queues/no-such-queue.json"

      assert_equal 404, response.status
    end


  end # class TestServer < Test::Unit::TestCase


end # module TestCurlicue
