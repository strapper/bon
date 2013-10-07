Net = require 'net'

class EC2Tunnel
  start: (ssh, callback) ->
    createServer = =>
      port   = Math.floor (Math.random() * 65535) + 1000
      server = Net.createServer (socket) =>
        ssh.exec 'sudo socat - UNIX-CONNECT:/var/run/docker.sock', (err, stream) ->
          return if err?

          socket.pipe stream
          stream.pipe socket

      server.on 'error', =>
        createServer()

      server.listen port, '127.0.0.1', =>
        # Don't let the server keep the event loop open.
        server.unref()
        
        callback? null, "http://127.0.0.1:#{port}"

    createServer()

module.exports = EC2Tunnel