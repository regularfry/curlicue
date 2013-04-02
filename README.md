Curlicue
========

A dead simple queue publishing system.

Introduction
------------

Curlicue allows you to push primitive messages to named queues which are
then published over HTTP.  The messages are stored to SQLite
databases, one per queue.  Each message is assigned a cursor value.
When the client retrieves messages from a queue, they can provide a
cursor value to retrieve messages from, and they will only retrieve
messages published *since* that cursor (exclusive).

All messages are timestamped.

Publishing API
--------------

### Creating a queue and publishing a message

    require 'curlicue'
    curly = Curlicue.exchange( "/tmp" )
    curly.push( "my-queue-name", 'a' => 'b' ) # => 1

If you don't want to keep specifying the queue name, this also works:


    my_queue = curly.get_queue( "my-queue-name" )
    my_queue.push( 'c' => 'd' ) => 2

### Serving a set of queues

    rack_app = Curlicue.server( curly ) 

This is a Sinatra app.  Mount it however you want, but this works nicely:

    require 'rack/handler/puma'
    Rack::Handler::Puma.run( rack_app )


Read API
--------

When you retrieve messages, you'll get a JSON array of hashes.  Each hash
has the keys 'cursor' and 'content'.  You need to keep track of the last 
'cursor' value you saw so that when you request the next set of messages,
you don't get any you've already seen.

The 'content' value is simply the message passed to the #push method above.

### Getting all messages in a queue

    GET /queues/my-queue-name.json
    
### Getting all messages since cursor 42

    GET /queues/my-queue-name.json?from=42
    
This will return messages 43 onwards.

### Only retrieve the first 23 messages

    GET /queues/my-queue-name.json?limit=23


Author
------

Alex Young <alex@blackkettle.org>
