# madtalk client.coffee
channel = io.connect '/0'

# channel.on 'connect', ->
#   channel.emit 'hi!'

channel.on 'connected', (id) ->
  console.log 'connected', id

channel.on 'message', (data) ->
  console.log data

$ -> # dom ready
