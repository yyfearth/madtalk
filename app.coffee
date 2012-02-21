# madtalk app.coffee
express = require 'express'
app = express.createServer()
io = require('socket.io').listen app
io.set 'transports', [
  'websocket'
  'flashsocket'
]

port = 8008

app.configure ->
  app.use express.static __dirname + '/public'
  app.set 'view engine', 'coffee'
  app.register '.coffee', require('coffeekup').adapters.express

app.get '/', (req, res) ->
  console.log 'A client has requested this route.'
  #id = new Date().getTime()
  #id++ while channels.index[id]
  id = 0 # test
  res.redirect '/' + id

app.get /^\/[\w\-]+\/?$/, (req, res) -> # '.' is not allowed
  res.render 'index' #, locals: port : port

channels = []
channels.index = {}

id = 0 # test

channel = io.of '/' + id
channel.records = []
# channel.users = []
# channel.users.index = {}

channel.on 'connection', (socket) ->
  console.log 'a user conn, wait for login ...', socket.id
  socket.on 'login', (user, callback) ->
    # if user is valid
    return callback err: 'invalid user' unless user?.nick

    # valid user
    # if user.id && channel.users.index[id]?
    #   ouser = channel.users.index[id]
    #   delete channel.users.index[id]
    #   ouser.nick = user.nick # overwrite
    #   user = ouser # pick org user info
    #   user.uid = socket.id
    # else
    #   user.uid = socket.id
    #   channel.users.push user # add user to list
    # channel.users.index[user.uid] = user # build index

    # broadcast one user connected
    # broadcasting means sending a message to everyone ELSE
    socket.broadcast.emit 'online', user
    # listen and re-broadcast messages
    socket.on 'message', (data, callback) ->
      data.user = user
      data.ts = new Date().getTime()
      console.log data
      # broadcasting means sending a message to everyone ELSE
      #socket.broadcast.emit 'message', data
      channel.emit 'message', data
      channel.records.push data
      callback yes

    socket.on 'disconnect', ->
      socket.broadcast.emit 'offline', user
      # todo: drop res

    records = channel.records#.filter (rec) ->
    # callback to user for successful login
    callback user, records

app.listen port
console.log "app listening on port #{port} ..."
