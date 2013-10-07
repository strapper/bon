Fs     = require 'fs'
Events = require 'events'
Crypto = require 'crypto'

getFileHash = (file, callback) ->
  shasum = Crypto.createHash 'sha512'
  stream = Fs.createReadStream file

  stream.on 'data', (data) ->
    shasum.update data

  stream.on 'end', ->
    callback? null, shasum.digest 'hex'

class File extends Events.EventEmitter
  constructor: ->
    @once 'uploaded', (err) ->
      @on 'newListener', (evnt, listener) ->
        return unless evnt == 'uploaded'

        process.nextTick ->
          @removeListener evnt, listener
          listener.call null, err

module.exports = {
  getFileHash,
  File
}