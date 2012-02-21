{exec} = require 'child_process'
xcoffee = require 'extra-coffee-script'

task 'build:src', 'Build project from src/*.coffee to lib/*.js', ->
  exec 'xcoffee -cxm --output lib/ src/', (err, stdout, stderr) ->
    throw err if err
    console.log stdout + stderr

task 'build:client', 'Build client', ->

