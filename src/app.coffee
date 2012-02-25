# madtalk app.coffee for dev use

# for server
express = require 'express'
app = express.createServer()
io = require('socket.io').listen app
io.set 'transports', [
  'websocket'
]
# for compile
fs = require 'fs'
stylus = require 'stylus'
xcoffee = require 'extra-coffee-script'

port = 8008

app.configure ->
  app.use express.static __dirname + '/public' # dev only
  #app.use express.gzip()
  app.set 'views', __dirname + '/views'
  app.set 'view engine', 'coffee'
  app.register '.coffee', require('coffeekup').adapters.express

app.get '/', (req, res) ->
  console.log 'A client has requested this route.'
  #id = new Date().getTime()
  #id++ while channels.index[id]
  id = 0 # test
  res.redirect '/' + id

app.get '/client.css', (req, res) ->
  filename = __dirname + '/styles/client.styl'
  fs.readFile filename, 'utf-8', (err, code) ->
      throw err if err
      stylus.render code, 
        filename: filename
        paths: [__dirname + '/styles/']
      , (err, css) ->
        throw err if err
        res.writeHead 200, 'Content-Type': 'text/css'
        res.end css, 'utf-8'
  #console.log 'stylus', css

app.get '/client.js', (req, res) ->
  filename = __dirname + '/scripts/client.coffee'
  fs.readFile filename, 'utf-8', (err, code) ->
    js = xcoffee.compile code, 
      filename: filename
      imports: on
    res.writeHead 200, 'Content-Type': 'application/javascript'
    res.end js, 'utf-8'
  #console.log 'stylus', css

app.get /^\/[\w\-]+\/?$/, (req, res) -> # '.' is not allowed
  res.render 'index', dev: yes

channels = []
channels.index = {}

id = 0 # test

channel = io.of '/' + id
channel.records = []
channel.users = []
channel.users.index = {}
channel.ts = new Date().getTime()

channel.on 'connection', (socket) ->
  console.log 'a user conn, wait for login ...', socket.id
  socket.on 'login', (user, callback) ->
    # if user is valid
    return callback err: 'invalid user' unless user?.nick

    # valid user
    if user.id and (u = channel.users.index[id])?
      # offline user
      delete channel.users.index[id]
      if u.nick isnt user.nick
        # u.old_nick = u.nick # do not care, as a new user
        u.nick = user.nick # overwrite
      u.uid = socket.id
      user = u # pick org user info
    else if user.nick and (u = channel.users.index[user.nick])?
      # not offline user, and nick dup
      return callback err: 'dup nick' if u.status isnt 'offline'
      u.uid = socket.id
      user = u # pick org user info
    else # new user
      user.uid = socket.id
      channel.users.push user # add user to list
    channel.users.index[user.nick] = channel.users.index[user.uid] = user # build index

    user.status = 'online'
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
      user.status = 'offline'
      socket.broadcast.emit 'offline', user
      # todo: drop res

    #records = channel.records#.filter (rec) ->
    # callback to user for successful login
    callback user,
      records: channel.records
      users: channel.users
      ts: channel.ts

app.listen port
console.log "app listening on port #{port} ..."
