# encoding: utf-8

require 'fileutils'

require 'curlicue/qdb'
require 'curlicue/queue'


module Curlicue


  # Public: Class to push messages to named queues, and to retrieve
  # JSON from them.
  class Exchange
    
    attr_reader :db_loader

    # Public: Convenience constructor.  Pass a dirname, get an
    # Exchange with appropriate defaults.
    #
    # dir - a directory name
    #
    # Returns an Exchange instance.
    def self.for_dir( dir )
      new( DirDbLoader.new( dir ) )
    end


    # Internal
    def initialize( db_loader )
      @db_loader = db_loader
    end


    # Public: Convenience method to get a Curlicue::Queue object
    # associated with a given name.  Note that Exchange doesn't
    # maintain a set of Queue objects, it creates a new instance per
    # request.
    #
    # queue_name - the name of the queue as a String.
    def get_queue( queue_name )
      if qdb = dbload( queue_name )
        Queue.new( qdb )
      else
        nil
      end
    end

    
    # Public: Push a message (which should be a Hash or Array of
    # primitives) to the named queue.  If the queue did not previously
    # exist, create it.
    # 
    # queue_name - the name of the queue as a String.
    # message    - the object to push, as either a Hash or an Array.
    #
    # Returns the cursor value assigned to the message.
    def push( queue_name, message )
      qdb = dbensure( queue_name )
      Queue.new( qdb ).push( message )
    end


    # Internal: Pull the contents of the named queue as a JSON string.
    # This is used by the Server as the HTTP response body.
    #
    # queue_name - the name of the queue as a String.  
    # opts       - a Hash of options to specify which messages to 
    #              return (default {}):
    #              :from  - the cursor immediately *before* the first 
    #                       message to return
    #              :limit - the maximum number of messages to return
    # 
    # Returns a string in JSON format if the named queue exists.
    # Returns nil otherwise.
    def pull_json( queue_name, opts = {} )
      if qdb = dbload( queue_name )
        Queue.new( qdb ).pull_json( opts )
      else
        nil
      end
    end


    private

    def dbload( name )
      db_loader.load( name )
    end

    def dbensure( name )
      db_loader.ensure( name )
    end

  end



  # Internal: Triggers loading and creating of Curlicue::Qdb objects
  # depending on directory contents.
  class DirDbLoader
    attr_reader :dir
    
    # Internal: strap a loader to a directory.
    #
    # dir - the String directory name to work in.
    def initialize( dir )
      @dir = dir
    end


    # Internal: Load a pre-existing queue database.
    #
    # name - the String name of the queue to load.
    #
    # Returns a Qdb instance if the named queue exists.
    # Returns nil otherwise.
    def load( name )
      Qdb.load( dir, name )      
    end


    # Internal: Load a pre-existing queue database if it exists, and
    # create it if not.
    #
    # name - the String name of the queue to load or create.
    #
    # Returns a Qdb instance.
    def ensure( name )
      locking( name ) do
        load( name ) || construct( name )
      end
    end


    private
    # We need to lock in case more than one process tries to ensure a
    # queue exists at the same time
    def locking( name )
      lock_name = File.join( dir, ".#{name}.lock" ) 
      FileUtils.touch( lock_name )
      File.open( lock_name, "r+" ) do |f|
        begin
          # TODO: FLOCK_NB, back-off and retry in case of failure?
          f.flock( File::LOCK_EX )
          yield
        ensure
          f.flock( File::LOCK_UN )
        end
      end
    end


    def construct( name )
      Qdb.construct( dir, name )
    end
    

  end # class DirDbLoader






end # module Curlicue
