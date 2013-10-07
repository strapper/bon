Fs            = require 'fs'
Crypto        = require 'crypto'
URL           = require 'url'
Zlib          = require 'zlib'
Request       = require 'request'
{getFileHash} = require './file'
{File}        = require './file'

class Server
  constructor: (@address) ->
    @files = {}

  start: (image, command, options, callback) ->
    if typeof options == 'function'
      callback = options
      options  = {}

    if typeof command == 'object' and not command instanceof Array
      options = command
    else
      options.cmd = command
    
    return callback? new Error "No command specified" unless options.cmd?

    getFileHash image, (err, hash) =>
      file = @files[hash]

      if not file?
        file   = @files[hash] = new File()
        stream = Fs.createReadStream(image).pipe Zlib.createGzip()

        stream.pipe Request.post
          url:  URL.resolve @address, '/images/create?fromSrc=-'
          json: true
        , (err, res, body) ->
          return file.emit 'uploaded', new Error 'Could not create remote image' if err? or res.statusCode != 200 or not body?.status?
          file.emit 'uploaded', null, body.status

      file.on 'uploaded', (err, imageId) =>
        return callback? err if err?

        Request.post
          url:  URL.resolve @address, '/containers/create'
          json:
            Image: imageId
            Cmd:   options.cmd
        , (err, res, body) =>
          containerId = body?.Id
          return callback? new Error 'Could not create remote container' if err? or res.statusCode != 201 or not containerId

          Request.post
            url:  URL.resolve @address, "/containers/#{containerId}/start"
            json: {}
          , (err, res, body) =>
            return callback? new Error 'Could not start remote container' if err? or res.statusCode != 204
            callback? null

module.exports = Server