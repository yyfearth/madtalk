# madtalk client.coffee
channel = io.connect()

channel.on 'connect', ->
  channel.emit 'hi!'

$ -> # dom ready
