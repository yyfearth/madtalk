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
    @io = require('socket.io').listen @svr
    @io.set 'browser client', false
    @io.set 'log level', 1
    @io.set 'transports', [
      'websocket'
    ]
    # prepare static files
    @prepare =>
      @svr.listen @port
      console.log "app listening on port #{@port} ..."
      return
  # end of constructor
  files:
    path: path.join __dirname, 'public'
    regex: /^\/(favicon\.ico|client\.(?:html|js|css))(?:\?\d+)?$/ # no index.html
    client: 'client.html'
    mime:
      'favicon.ico' : 'image/x-icon'
      'client.js'   : 'application/javascript'
      'client.css'  : 'text/css'
      'client.html' : 'text/html'
  prepare: (callback) ->
    c = @cache = list: []
    files = Object.getOwnPropertyNames @files
    timeout = setTimeout ->
      throw 'load files timeout'
    , 30*1000 # 30s
    for f, t of @files.mime then do (f, t) =>
      file = path.join @files.path, f
      gzfile = file + '.gz'
      fs.stat gzfile, (err, stat) ->
        throw err if err
        # org_stat = fs.statSync file
        fs.readFile gzfile, 'binary', (err, data) =>
          throw err if err
          c[f] =
            name: f
            gz: data
            mtime: stat.mtime
            type: t
            # size: org_stat.size
          c.list.push f
          console.log 'load file to cache', f
          if c.list.length is files.length
            clearTimeout timeout
            callback() 
          return
        return
      return
  routing: (req, res) ->
    return unless @chkUA req, res
    # console.log 'routing', req.url
    if req.url is '/'
      # root
      console.log 'A client has requested this route.'
      id = new Date().getTime()
      id++ while Channel.has (str_id = id.toString 36)
      # res.redirect '/' + str_id
      res.writeHead 302, 'Location': '/' + str_id
      res.end()
    else if req.url.length > 1 and req.url[-1..] is '/'
      # end with /
      # res.redirect req.url[0...-1], 301
      res.writeHead 301, 'Location': req.url[0...-1]
      res.end()
    else if Channel.ID_REGEX.test req.url
      # channel
      id = req.url
      Channel.create {id, @io} unless Channel.has id
      @serve @files.client, req, res
    else if @files.regex.test req.url
      # static files
      file = req.url.match @files.regex
      # console.log 'routing file', req.url, file
      @serve file[1], req, res
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
  
  MAX_AGE: 30 * 24 * 60 * 60 * 1000 # 30 days
  serve: (file, req, res) ->
    console.log 'serve file', file
    data = @cache[file]
    lastmod = req.headers['if-modified-since']
    etag = req.headers['if-none-match']
    if lastmod and etag and etag is data.etag and data.mtime is new Date(lastmod).getTime()
      res.writeHead 304, "Not Modified"
      res.end
      return

    res.setHeader 'Content-Type', data.type # mime
    res.setHeader 'Content-Encoding', 'gzip'
    res.setHeader 'Vary', 'Accept-Encoding'
    res.setHeader 'Content-Length', data.gz.length
    res.setHeader 'Last-Modified', data.mtime.toUTCString()
    res.setHeader 'Date', new Date().toUTCString()
    res.setHeader 'Expires', new Date(data.mtime.getTime() + @MAX_AGE).toUTCString()
    res.setHeader 'Cache-Control', 'public, max-age=' + (@MAX_AGE / 1000)
    res.setHeader 'ETag', "\"#{data.gz.length}-#{Date.parse data.mtime}\""
    res.end data.gz, 'binary'
    return

app = App.create()
