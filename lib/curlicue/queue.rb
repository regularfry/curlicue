# encoding: utf-8

require 'json'

module Curlicue

  # Internal: Serialises messages to a store, and retrieves them in
  # serialised form.
  class Queue

    attr_reader :store

    # Internal: wrap a store, which will usually be a Qdb instance.
    # 
    # store - anything responding to #push and #pull.
    def initialize( store )
      @store = store
    end


    # Internal: Serialise content and push it to the store.
    # Serialisation is done with JSON.dump.
    #
    # content - the object to serialise.  This should be a String,
    #           Hash or Array.
    #
    # Returns the cursor value assigned to this message content by the
    # store.
    def push( content )
      store.push( JSON.dump( content ) )
    end

    
    # Internal: Fetch a list of messages, as JSON, from the store.
    #
    # opts - see Qdb#pull_json.
    #
    # Returns a String in JSON format.
    def pull_json( opts = {} )
      messages = store.pull( opts )
      if messages.empty?
        "[]"
      else
        messages_to_json( messages )
      end
    end


    private
    def messages_to_json( messages )
      # Slight gymnastics here: the content is stored as a JSON
      # string, so to avoid building a bunch of interim objects only
      # to do a JSON.dump and then throw them away, we just cat the
      # strings together and build the json by hand.

      json = "["
      messages.each do |msg|
        json << %Q{\{"cursor":#{msg['cursor']},}
        json << %Q{"content":#{msg['content']}\},}
      end
      json[-1] = "]" # overwrite the trailing comma
      json
    end
    

  end



end
