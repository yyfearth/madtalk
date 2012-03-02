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

app.get '/', (req, res) ->
  console.log 'A client has requested this route.'
  id = new Date().getTime().toString 36
  id++ while Channel.has id
  res.redirect '/' + id

#app.get '/client.css', (req, res) ->
# stylus_file = __dirname + '/styles/client.styl'
# compile_stylus = (callback) ->
#   fs.readFile stylus_file, 'utf-8', (err, code) ->
#       throw err if err
#       # stylus(code)
#       # .set('filename', filename)
#       # .set('paths', [__dirname + '/styles/'])
#       # .set('compress', on)
#       # .use(nib())
#       # .render (err, css) ->
#       stylus.render code, 
#         filename: filename
#         paths: [__dirname + '/styles/']
#       , (err, css) ->
#         throw err if err
#         callback css
        # res.writeHead 200, 'Content-Type': 'text/css'
        # res.end css, 'utf-8'
  #console.log 'stylus', css

# app.get '/client.js', (req, res) ->
# coffee_file = __dirname + '/scripts/client.coffee'
# compile_coffee = (callback) ->
#   fs.readFile coffee_file, 'utf-8', (err, code) ->
#     js = xcoffee.compile code, 
#       filename: filename
#       imports: on
#     callback js
    # res.writeHead 200, 'Content-Type': 'application/javascript'
    # res.end js, 'utf-8'
  #console.log 'stylus', css
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
  # create channel
  id = req.url
  Channel.create {id, io} unless Channel.has id
  # compile
  o = dev: yes
  compile_stylus (css) ->
    o.css = css
    o.js = compile_coffee()
    res.render 'index', o
  # render index


app.listen port
console.log "app listening on port #{port} ..."
