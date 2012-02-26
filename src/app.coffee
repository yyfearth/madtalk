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
# modules
{Channel} = require './modules/Channel'

port = 8008

app.configure ->
  app.use express.static __dirname + '/public' # dev only
  #app.use express.gzip()
  app.set 'views', __dirname + '/views'
  app.set 'view engine', 'coffee'
  app.register '.coffee', require('coffeekup').adapters.express

app.get '/', (req, res) ->
  console.log 'A client has requested this route.'
  id = new Date().getTime()
  id++ while Channel.has id
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

app.get /^\/.+?\/$/, (req, res) -> # /id/ -> /id
  res.redirect req.url[0...-1], 301

app.get Channel.ID_REGEX, (req, res) -> # '.' is not allowed
  # create channel
  id = req.url
  Channel.create {id, io} unless Channel.has id
  # render index
  res.render 'index', dev: yes

app.listen port
console.log "app listening on port #{port} ..."
