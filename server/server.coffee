# madtalk server.coffee

io = require('socket.io').listen 8008

id = 0 # test

channel = io
  .of("/madtalk/#{id}")
  .on('connection', (socket) ->
    socket.emit 'message',
      that: 'only'
      "/madtalk/#{id}": 'will get'
    channel.emit 'message',
      everyone: 'in'
      "/madtalk/#{id}": 'will get'
