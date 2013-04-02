# encoding: utf-8

require 'test/unit'
require 'tmpdir'
require 'fileutils'

require 'curlicue/qdb'


module TestCurlicue

  class TestQdb < Test::Unit::TestCase
    include Curlicue


    def setup
      @dir = Dir.mktmpdir
    end

    def teardown
      FileUtils.remove_entry_secure( @dir )
    end


    def test_construct_makes_new_database
      queue_name = "my-queue-name"
      qdb = Qdb.construct( @dir, queue_name )
      
      assert File.file?( File.join( @dir, queue_name + ".q.db" ) )
    end


    def test_load_existing_database
      queue_name = "my-queue-name"
      qdb = Qdb.construct( @dir, queue_name )
      qdb.push( "foobar" )
      
      newdb = Qdb.load( @dir, queue_name )
    end



    def test_load_all_queues
      names = %w{a b c}
      names.each do |queue_name|
        Qdb.construct( @dir, queue_name )
      end
      
      qdbs = Qdb.load_all( @dir )

      assert_equal 3, qdbs.length
      assert_equal names, qdbs.map{|qdb| qdb.name}
    end



    def test_has_schema_version
      assert_equal "1", Qdb.new( in_mem_db ).schema_version
    end



    def test_push_returns_cursors
      qdb = Qdb.new( in_mem_db )
      assert cursor1 = qdb.push( "MESSAGE_CONTENTS" ), "No cursor was returned"
      assert cursor2 = qdb.push( "SECOND_MESSAGE_CONTENTS" ), "Second cursor was not returned"

      assert_not_equal cursor1, cursor2, "Cursors should not be the same."
    end

    
    def test_pull_returns_list
      qdb = Qdb.new( in_mem_db )
      assert_equal [], qdb.pull
    end


    def test_pull_returns_message
      qdb = Qdb.new( in_mem_db )
      qdb.push( 'a' )
      
      list = qdb.pull
      assert_equal 1, list.length
    end


    def test_pull_adds_cursor_to_messages
      qdb = Qdb.new( in_mem_db )
      qdb.push( 'a' )

      msg = qdb.pull.first
      assert_equal 1, msg['cursor']
    end


    def test_content_survives_roundtrip
      content = "message content"
      
      qdb = Qdb.new( in_mem_db )
      qdb.push( content )
      
      msg = qdb.pull.first
      assert_equal content, msg['content']
    end

    
    def test_pull_respects_limit
      qdb = Qdb.new( in_mem_db )
      3.times do |i|
        qdb.push( i.to_s )
      end

      list = qdb.pull( :limit => 2 )
      assert_equal 2, list.length
    end


    def test_pull_respects_from
      qdb = Qdb.new( in_mem_db )
      
      cursors = (0...3).map { |i|
        qdb.push( i.to_s )
      }

      list = qdb.pull( :from => cursors.first )
      assert_equal 2, list.length

      assert_equal( cursors[1..-1], 
                    list.map{|m| m['cursor']} )
    end

    
    def test_pull_from_with_limit
      qdb = Qdb.new( in_mem_db )
      cursors = (0...10).map {|i|
        qdb.push( i.to_s )
      }

      list = qdb.pull( :from => cursors.first,
                       :limit => 8 )
      assert_equal 8, list.length
      assert_equal 9, list.last['cursor']
    end


    def test_prune
      qdb = Qdb.new( in_mem_db )
      qdb.push('a')

      qdb.prune
      
      assert qdb.pull.empty?
    end


    def test_prune_to
      qdb = Qdb.new( in_mem_db )
      prune_to = qdb.push("a")
      qdb.push("b")
      
      qdb.prune( :to => prune_to )

      list = qdb.pull
      assert_equal 1, list.length
      assert_equal "b", list.first['content']
    end



    private
    def in_mem_db
      db = Amalgalite::MemoryDatabase.new
      Qdb.construct_tables( db )
    end
  end

end
