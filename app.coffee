# madtalk app.coffee
app = require('express').createServer()
io = require('socket.io').listen app

id = '/0' # test

channel = io
  .of(id)
  .on 'connection', (socket) ->
    msg = that: 'only'
    msg[id] = 'will get'
    socket.emit 'message', msg

    msg = everyone: 'in'
    msg[id] = 'will get'
    channel.emit 'message', msg

app.use express.static __dirname + '/public'

app.get '/0', (req, res) ->
  console.log('A client has requested this route.');


app.listen 8008
