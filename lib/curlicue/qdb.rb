# encoding: utf-8

require 'amalgalite'

module Curlicue


  # Internal: The queue database wrapper.  Here be SQL and SQLite
  # management via amalgalite.
  class Qdb
    
    class BadName < StandardError; end


    SCHEMA_VERSION = "1"


    # Internal: Build a new queue database.
    # If this is called when the queue already exists, Amalgalite will
    # silently load the existing one and try to construct new tables,
    # which will fail.  Don't call this without a lock held.
    #
    # dir        - the String directory path to build it in
    # queue_name - the String name on which to base the db filename
    #
    # Returns a Qdb instance
    def self.construct( dir, queue_name )
      db = Amalgalite::Database.new( filename( dir, queue_name ) )
      new( construct_tables( db ), queue_name )
    end


    # Internal: construct a db filename out of a directory name and a
    # queue name
    # 
    # dir        - the String directory path to assume
    # queue_name - the String queue name to include
    #
    # Returns the string file path.
    def self.filename( dir, queue_name )
      actual_name = File.basename( queue_name )
      unless actual_name == queue_name
        raise BadName.new( "Names must be filesystem-compatible as filenames." )
      end
      File.join( dir, actual_name + ".q.db" )
    end

    
    # Internal: Load an existing queue database.
    #
    # dir        - the String directory path in which to look.
    # queue_name - the name of the queue to load
    #
    # Returns a Qdb if the named queue exists.
    # Returns nil otherwise.
    def self.load( dir, queue_name )
      db_name = filename( dir, queue_name )

      if File.file?( db_name )
        db = Amalgalite::Database.new( db_name )
        new( db, queue_name )
      else
        nil
      end
    end


    # Internal: Load all the databases in the given directory.
    #
    # dir - the directory in which to look
    # 
    # Returns an Array of Qdb instances.
    def self.load_all( dir )
      Dir[ File.join( dir, "*.q.db" ) ].sort.map do |filename|
        load( dir, File.basename( filename, ".q.db" ) )
      end
    end



    # Internal: inject the schema into a database.
    #
    # db - an Amalgalite::Database instance.
    # 
    # Returns db.
    def self.construct_tables( db )
      db.execute( <<-SQL )
CREATE TABLE info (
  schema_version TEXT
);
SQL
      db.execute( "INSERT INTO info (schema_version) VALUES (?)", SCHEMA_VERSION )


      db.execute( <<-SQL )
CREATE TABLE messages (
  id integer primary key,
  content text
);
      SQL

      db
    end


    attr_reader :db
    attr_reader :name

    # Internal: wrap a database for queue operations.  The database
    # must already have the schema injected by Qdb.construct_tables.
    #
    # db   - the Amalgalite::Database instance.
    # name - an optional name for this instance.
    def initialize( db, name = nil )
      @db = db
      @name=name
    end


    # Internal: get the version of the schema stored in the database.
    #
    # Returns a String of the schema version.
    def schema_version
      exec_one_result( "SELECT schema_version FROM info" )
    end

    
    # Internal: insert a serialised message into the queue.  This
    # method does not do serialisation, that must happen elsewhere.
    #
    # contents - the String contents to insert.
    # 
    # Returns the row id of the message.
    def push( contents )
      query( "INSERT INTO messages (content) VALUES (?)", contents )
      db.last_insert_rowid
    end


    # Internal: fetch a list of messages from the queue.
    #
    # opts - a Hash which specifies the messages to retrieve (default {}):
    #        :limit - the maximum number to return
    #        :from  - a number below the id of the first message to return
    #
    # Returns an Array of Hashes of the format:
    #    'cursor'  - the row id
    #    'content' - the String message content
    def pull( opts = {} )
      limit = opts.fetch( :limit, nil )
      from = opts.fetch( :from, 0 )

      query = "SELECT * FROM messages WHERE id > ?"
      bind_args = [from]

      if limit
        query += " LIMIT ?"
        bind_args << limit
      end

      rows = query( query, *bind_args )

      rows.map{|row| 
        { 'cursor' => row['id'],
          'content' => row['content'] }
      }
    end


    # Internal: delete messages from the queue.
    #
    # opts - a Hash which specifies the messages to delete (default: {})
    #        :to - the id of the last message to delete
    def prune( opts = {} )
      prune_to = opts.fetch( :to, nil )
      
      qry = "DELETE FROM messages"
      bind_args = []

      if prune_to
        qry += " WHERE id <= ?"
        bind_args << prune_to
      end
      
      query( qry, *bind_args )
    end
    

    private


    def query( *args, &blk )
      db.execute( *args, &blk )
    end

    def exec_one( *args, &blk )
      db.first_row_from( *args, &blk )
    end

    def exec_one_result( *args, &blk )
      db.first_value_from( *args, &blk )
    end


  end

end
