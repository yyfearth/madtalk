# madtalk app.coffee for production use

# for server
port = 8008
# express = require 'express'
# app = express.createServer()
io = require('socket.io').listen port
# for production
io.enable 'browser client etag'
io.enable 'browser client minification'
io.enable 'browser client gzip'
io.set 'browser client handler', (req, res) ->
  console.log req
  # res.end JSON.stringify req
# dev setting
io.set 'log level', 2
io.set 'transports', [
  'websocket'
]
# for compile
fs = require 'fs'
# modules
{Channel} = require './modules/channel'


# app.configure ->
#   app.use express.static __dirname + '/public' # dev only
#   #app.use express.gzip()
#   app.set 'views', __dirname + '/views'
#   app.set 'view engine', 'coffee'
#   app.register '.coffee', require('coffeekup').adapters.express

# app.get '/', (req, res) ->
#   console.log 'A client has requested this route.'
#   id = new Date().getTime().toString 36
#   id++ while Channel.has id
#   res.redirect '/' + id

# app.get /^\/.+?\/$/, (req, res) -> # /id/ -> /id
#   res.redirect req.url[0...-1], 301

# app.get Channel.ID_REGEX, (req, res) -> # '.' is not allowed
#   # create channel
#   id = req.url
#   Channel.create {id, io} unless Channel.has id
#   # compile
#   o = dev: yes
#   compile_stylus (css) ->
#     o.css = css
#     o.js = compile_coffee()
#     res.render 'index', o
#   # render index

console.log "app listening on port #{port} ..."
