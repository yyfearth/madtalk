# madtalk app.coffee for dev use

# for server
express = require 'express'
app = express.createServer()
io = require('socket.io').listen app
### for production
io.enable 'browser client etag'
io.enable 'browser client minification'
io.enable 'browser client gzip'
io.set 'browser client handler', (req, res) ->
###
# dev setting
io.set 'log level', 2
io.set 'transports', [
  'websocket'
]
# for compile
fs = require 'fs'
stylus = require 'stylus'
#nib = require 'nib'
xcoffee = require 'extra-coffee-script'
# modules
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
  id = new Date().getTime().toString 36
  id++ while Channel.has id
  res.redirect '/' + id

compile_stylus = (callback) ->
  stylus.render '@import "client"', 
    #filename: __dirname + '/styles/client.stylus'
    paths: [__dirname + '/styles/']
    compress: on
  , (err, css) ->
    throw err if err
    callback css

compile_coffee = ->
  xcoffee.compile 'import "client"',
    filename: __dirname + '/scripts/client.coffee'
    imports: on

app.get /^\/.+?\/$/, (req, res) -> # /id/ -> /id
  res.redirect req.url[0...-1], 301

app.get Channel.ID_REGEX, (req, res) -> # '.' is not allowed
  return unless chk_ua req, res
  # create channel
  id = req.url
  Channel.create {id, io} unless Channel.has id
  # compile
  o = dev: yes
  compile_stylus (css) ->
    o.css = css
    o.js = compile_coffee()
    res.render 'client', o
  # render client


app.listen port
console.log "app listening on port #{port} ..."
