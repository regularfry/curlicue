# encoding: utf-8

module TestCurlicue

  class MemQdb    

    def initialize
      @q = []
      @last_insert_id = 0
    end


    def push( content )
      cursor = @last_insert_id
      @q << [cursor, content]
      @last_insert_id += 1
      cursor
    end


    def pull( opts = {} )
      from = opts.fetch( :from, nil )
      limit = opts.fetch( :limit, nil)

      msgs = @q.select{ |c,m|
        from.nil? || c > from.to_i
      }.map{ |c,m|
        {'cursor' => c,
          'content' => m}
      }

      limit ? msgs[0...limit] : msgs
    end


    def get_content( cursor )
      @q.find{|a,b| a == cursor}[1]
    end


  end

  
end
