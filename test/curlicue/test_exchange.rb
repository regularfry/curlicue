# encoding: utf-8

require 'test/unit'
require 'fileutils'
require 'tmpdir'

require 'json'

require 'curlicue/exchange'
require 'curlicue/qdb'

module TestCurlicue

  class TestExchange < Test::Unit::TestCase

    include Curlicue

    
    def setup
      @dir = Dir.mktmpdir
      @loader = DirDbLoader.new( @dir )
    end
    
    def teardown
      FileUtils.remove_entry_secure( @dir )
    end


    def test_get_queue
      queue_name = "my-queue-name"

      exchange = Exchange.new( @loader )

      qdb = Qdb.construct( @dir, queue_name )
      qdb.push( JSON.dump( "a" => "b" ) )
      
      assert q = exchange.get_queue( queue_name )
      assert_equal 'b', JSON.load( q.pull_json )[0]['content']['a']
    end

    
    def test_push
      queue_name = "my-queue-name"
      exchange = Exchange.new( @loader )
      
      exchange.push( queue_name, {"a" => "b"} )
      assert_equal 'b', JSON.load( exchange.pull_json( queue_name ) )[0]['content']['a']
    end


  end
end
