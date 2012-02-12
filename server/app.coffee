# server app.coffee

io = require('socket.io').listen 8008

channel = io
  .of("/madtalk/#{id}")
  .on('connection', (socket) ->
    socket.emit 'a message',
      that: 'only'
      "/madtalk/#{id}": 'will get'
    channel.emit 'a message',
      everyone: 'in'
      "/madtalk/#{id}": 'will get'
