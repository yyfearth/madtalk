# madtalk app.coffee for dev use

# for server
express = require 'express'
app = express.createServer()
io = require('socket.io').listen app
# dev setting
io.set 'browser client handler', (req, res) ->
  # console.log req
  res.writeHead 404
  res.end 'resource not found'
  return
io.set 'log level', 2
io.set 'transports', [
  'websocket'
]
# for compile
fs = require 'fs'
# modules
build = require './modules/build'
{Channel} = require './modules/channel'

port = 8008

app.configure ->
  app.use express.static __dirname + '/public' # dev only
  #app.use express.gzip()
  app.set 'views', __dirname + '/views'
  app.set 'view engine', 'coffee'
  app.register '.coffee', require('coffeekup').adapters.express

chk_ua = (req, res) ->
  ua = req.headers['user-agent']
  if /MSIE [1-9]\./i.test ua
    res.end 'This WebApp does not support IE below 10!'
    false
  else if /opera/i.test ua
    res.end 'This WebApp does not support Opera!'
    false
  else if /Mozilla\/4/i.test ua
    res.end 'This WebApp does not support your browser! \nIt seems your browser is out of date.'
    false
  else
    true

app.get '/', (req, res) ->
  return unless chk_ua req, res
  console.log 'A client has requested this route.'
  id = new Date().getTime()
  id++ while Channel.has (str_id = id.toString 36)
  res.redirect '/' + str_id

compile_stylus = (callback) ->
  build.stylus __dirname + '/styles/client.styl'
    paths: [__dirname + '/styles/']
    callback
    # compress: 'min'

compile_coffee = -> # sync
  build.coffee __dirname + '/scripts/client.coffee'
    # minify: on
# compile_coffee = (callback) -> # async
#   build.coffee
#     filename: __dirname + '/scripts/client.coffee'
#     callback

app.get /^\/[^\/]+\/$/, (req, res) -> # /id/ -> /id
  res.redirect req.url[0...-1], 301

app.get Channel.ID_REGEX, (req, res) -> # '.' is not allowed
  return unless chk_ua req, res
  # create channel
  id = req.url
  # console.log id
  Channel.create {id, io} unless Channel.has id
  # compile
  o = dev: yes
  compile_stylus (css) ->
    o.css = css
    o.js = compile_coffee()
    res.render 'client', o
  # render client

# Handle SIGUSR2, but only once
process.once 'SIGUSR2', ->
  console.log 'Doing shutdown tasks... (nothing yet)'
  # async
  process.kill process.pid, 'SIGUSR2'
  return

app.listen port
console.log "app listening on port #{port} ..."
