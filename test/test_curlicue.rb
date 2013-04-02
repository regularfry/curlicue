# encoding: utf-8

require 'tmpdir'
require 'test/unit'
require 'curlicue'

module TestCurlicue
  class TestCurlicue < Test::Unit::TestCase

    def setup
      @dir = Dir.mktmpdir
      @exchange = Curlicue.exchange( @dir )
      @message = {'a' => 'b'}
    end

    def teardown
      FileUtils.remove_entry_secure( @dir )
    end
    

    def test_exchange_builds_exchange
      assert cursor = push()
      assert_equal @message['a'], first_message( pull )['a']
    end


    def test_server_builds_rack_app
      
      Dir.mktmpdir do |dir|
        push()
        
        server = Curlicue.server( @exchange )
        status, headers, body = 
          server.call( "PATH_INFO"      => '/queues/new-queue.json',
                       "rack.input"     => '',
                       'REQUEST_METHOD' => "GET" )

        assert_equal 200, status
        assert headers
        assert_equal @message['a'], first_message( body.join("") )['a']
      end
    end



    private
    def push
      @exchange.push( "new-queue", @message )
    end

    def pull
      @exchange.pull_json( "new-queue" )
    end


    def first_message( json )
      JSON.parse( json )[0]['content']
    end
    
  end

end
