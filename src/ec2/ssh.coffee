require 'pork'

SSH    = require './../ssh'
Tunnel = require './tunnel'

process.on 'message', (msg) ->
  start = (callback) ->
    ssh = new SSH()

    ssh.connect msg.address, msg.port, msg.user, msg.privateKey, (err) ->
      return callback? err if err?

      tunnel = new Tunnel()
      tunnel.start ssh, (err, address) ->
        return callback? err if err?
        callback? null, address

  start (err, address) ->
    return process.send { index: msg.index, error: err.toString() } if err?
    process.send { index: msg.index, address: address }