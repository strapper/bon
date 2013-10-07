Net        = require 'net'
URL        = require 'url'
Fs         = require 'fs'
Zlib       = require 'zlib'
AWS        = require 'aws-sdk'
Connection = require 'ssh2'
Provider   = require './../provider'
Server     = require './../server'
{pork}     = require 'pork'

serverIdx  = 0
serverProc = pork "#{__dirname}/ssh.js"

class EC2Provider extends Provider
  start: (options, callback) ->
    config =
      accessKeyId:     options.accessKey
      secretAccessKey: options.secretAccessKey
      region:          options.region
      sslEnabled:      true

    return callback? new Error 'No Access Key Specified'        unless config.accessKeyId?
    return callback? new Error 'No Secret Access Key Specified' unless config.secretAccessKey?
    return callback? new Error 'No Region Specified'            unless config.region?

    ec2 = new AWS.EC2 config

    ec2.runInstances
      ImageId:        options.ami
      MinCount:       1
      MaxCount:       1
      InstanceType:   options.type
      KeyName:        options.ssh.name
      SecurityGroups: options.securityGroups
    , (err, data) ->
      return callback? err if err?

      instanceId = data.Instances[0].InstanceId

      waitForPublicDnsName = (callback) ->
        setTimeout ->
          ec2.describeInstances
            InstanceIds: [ instanceId ]
          , (err, data) ->
            return callback? new Error 'Failed to get Public DNS Name for Instance' if err?

            dnsName = data?.Reservations?[0].Instances?[0].PublicDnsName
            return waitForPublicDnsName callback unless dnsName? and dnsName.length > 0

            callback? null, dnsName
        , 5 * 1000

      waitForPublicDnsName (err, address) ->
        index = ++serverIdx

        serverProc.send
          index:      index
          address:    address
          port:       options.ssh.port ? 22
          user:       options.ssh.user
          privateKey: options.ssh.key

        handler = (msg) ->
          return unless msg.index == index
          serverProc.removeListener 'message', handler

          return callback? msg.error if msg.error?
          callback? null, new Server msg.address

        serverProc.on 'message', handler

module.exports = EC2Provider