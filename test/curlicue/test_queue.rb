# encoding: utf-8

require 'test/unit'
require 'curlicue/queue'
require 'test/curlicue/mem_qdb'

module TestCurlicue
  
  
  class TestQueue < Test::Unit::TestCase

    include Curlicue


    def test_push_serialises
      qdb = MemQdb.new
      q = Queue.new( qdb )
      
      cursor = q.push( {'a' => 'b'} )
      
      assert_kind_of String, content = qdb.get_content( cursor )
      assert_equal 'b', JSON.parse( content )['a']
    end


    def test_pull_json_provides_json_string
      qdb = MemQdb.new
      q = Queue.new( qdb )
      
      cursor = q.push( {'a' => 'b'} )
      
      assert_kind_of String, json_str = q.pull_json
      assert_kind_of Array, list = JSON.parse( json_str )
      assert_equal 1, list.length

      assert_equal 'b', list[0]['content']['a']
    end


    def test_pull_json_gives_valid_empty_list
      qdb = MemQdb.new
      q = Queue.new( qdb )
      
      assert_kind_of Array, list = JSON.parse( q.pull_json )
    end


  end # class TestQueue < Test::Unit::TestCase

end
