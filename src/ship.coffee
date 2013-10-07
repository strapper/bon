Fs           = require 'fs'
CoffeeScript = require 'coffee-script'
Ship         = require './index'

extend = (object, properties) ->
  for key, val of properties
    object[key] = val
  return object

tasks = {}

extend global,
  boot: Ship.boot

  ship: (name, description, action) ->
    [action, description] = [description, action] unless action?
    tasks[name] = { name, description, action }

run = ->
  CoffeeScript.run (Fs.readFileSync 'Shipfile').toString(), filename: 'Shipfile'

  task = process.argv[2]
  return (fatalError 'No task given') unless task?

  return missingTask task unless tasks[task]
  tasks[task].action()

missingTask = (task) ->
  fatalError "No such task: #{task}"

fatalError = (message) ->
  console.error "#{message}"
  process.exit 1

module.exports = {
  run
}