# madtalk app.coffee for production use

fs = require 'fs'
path = require 'path'
http = require 'http'

# modules
import './modules/channel'

class App
  @create: (port) -> new @ port
  constructor: (@port = 8008) ->
    @svr = http.createServer @routing.bind @
    @io = require('socket.io').listen app.svr
    @io.set 'browser client handler', (req, res) ->
      # console.log req
      res.writeHead 404
      res.end 'resource not found'
      return
    @io.set 'log level', 1
    @io.set 'transports', [
      'websocket'
    ]
    # prepare static files
    @prepare ->
      @svr.listen @port
      console.log "app listening on port #{@port} ..."
      return
  # end of constructor
  files:
    path: path.join __dirname, 'public'
    regex: /^\/(#{favicon\.ico|client.(?:html|js|css)})(?:\?\d+)?$/ # no index.html
    client: 'client.html'
    'favicon.ico': 'image/x-icon'
    'client.js'  : 'application/javascript'
    'client.css' : 'text/css'
    'client.html' : 'text/html'
  prepare: (callback) ->
    c = @cache = list: []
    files = Object.getOwnPropertyNames @files
    timeout = setTimeout ->
      throw 'load files timeout'
    , 30*1000 # 30s
    files.forEach (f) => fs.readFile (path.join @files.path, f + '.gz'), 'binary', (err, data) =>
      throw err if err
      c[f] =
        name: f
        content: data
        mtime: 0 # todo: get mtime
        type: @files[f]
      c.list.push f
      console.log 'load file to cache', f
      if c.list.length is files.length
        clearTimeout timeout
        callback() 
      return
    return
  routing: (req, res) ->
    return unless @chkUA req, res
    if req.url is '/'
      # root
      console.log 'A client has requested this route.'
      id = new Date().getTime()
      id++ while Channel.has (str_id = id.toString 36)
      res.redirect '/' + str_id
    else req.url.length > 1 and req.url[-1..] is '/'
      # end with /
      res.redirect req.url[0...-1], 301
    else if Channel.ID_REGEX.test req.url
      # channel
      id = req.url
      Channel.create {id, io} unless Channel.has id
      @serve @file.client, res
    else if files.regex.test req.url
      # static files
      file = req.url.match files.regex
      @serve file[1], res
    else
      res.writeHead 404
      res.end 'resource not found'
    return
  chkUA: (req, res) ->
    ua = req.headers['user-agent']
    if /MSIE [1-9]\./i.test ua
      msg = 'This WebApp does not support IE below 10!'
      false
    else if /opera/i.test ua
      msg = 'This WebApp does not support Opera!'
      false
    else if /^Mozilla\/4/i.test ua
      msg = 'This WebApp does not support your browser! \nIt seems your browser is out of date.'
      false
    else
      return true
    # res.writeHead 200, 'Content-Type': 'text/plain'
    res.end msg
    return
  serve: (file, res) ->
    console.log 'serve file', file
    data = @cache[file]
    res.setHeader 'Content-Type', @files[file] # mime
    res.setHeader 'Content-Encoding', 'gzip'
    res.setHeader 'Vary', 'Accept-Encoding'
    res.setHeader 'Content-Length', data.content.length
    # res.setHeader 'Last-Modified', data.mtime.toUTCString()
    res.setHeader 'Date', new Date().toUTCString()
    # res.setHeader 'Expires', new Date(Date.now() + clientMaxAge).toUTCString()
    # res.setHeader 'Cache-Control', 'public, max-age=' + (clientMaxAge / 1000)
    # res.setHeader 'ETag', '"' + data.content.length + '-' + data.mtime >>> 0 + '"'
    res.end data.content, 'binary'
    return

app = App.create()
