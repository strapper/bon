Fs         = require 'fs'
Connection = require 'ssh2'

class SSH
  constructor: ->
    @connection = new Connection()

  connect: (host, port, user, keyPath, callback) ->
    Fs.readFile keyPath, (err, privateKey) =>
      return callback? err if err?

      connect = =>
        @connection.connect
          host:       host
          port:       port
          username:   user
          privateKey: privateKey

      @connection.on 'ready', =>
        callback? null

      @connection.on 'error', =>
        connect()

      connect()

  exec: (cmd, callback) ->
    @connection.exec cmd, callback

module.exports = SSH