# madtalk app.coffee
express = require 'express'
app = express.createServer()
io = require('socket.io').listen app
io.set 'transports', [
  'websocket'
  'flashsocket'
]

port = 8008

channels = []
channels.index = {}

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

app.configure ->
    app.use express.static __dirname + '/public'
    app.set 'view engine', 'coffee'
    app.register '.coffee', require('coffeekup').adapters.express

app.get '/', (req, res) ->
  console.log 'A client has requested this route.'
  #id = new Date().getTime()
  #id++ while channels.index[id]
  id = 0 # test
  req.redirect id

app.get /^\/[\w\-]+\/?$/, (req, res) -> # '.' is not allowed
  res.render 'index' #, locals: port : port

app.listen port
console.log "app listening on port #{port} ..."
