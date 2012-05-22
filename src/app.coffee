# madtalk app.coffee for production use

PORT = 8008

fs = require 'fs'
path = require 'path'
http = require 'http'

# modules
import './modules/channel'

class App
  @create: (ip, port) -> new @ ip, port
  constructor: (@ip, @port = PORT) ->
    @svr = http.createServer @routing.bind @
    @io = require('socket.io').listen @svr
    @io.set 'browser client', off
    @io.set 'log level', 1
    @io.set 'transports', [
      'websocket'
    ]
    # prepare static files
    @prepare =>
      @svr.listen @port, @ip
      console.log "app listening on port #{@port} ..."
      return
  # end of constructor
  _load_cache: (buf) ->
    head_len = 0
    pad_len = 16
    pad_char = 0
    head_len++ while buf[head_len]
    head = buf.toString 'utf-8', 0, head_len
    try
      head = JSON.parse head
    catch e
      throw 'cannot parse package'
    throw 'unacceptable package version ' + head.v unless head.v is 1
    offset = head_len + pad_len
    # test padding
    throw 'read package error: head padding mismatch' if buf[offset - 1] isnt pad_char
    # load content
    files = head.files
    list = Object.getOwnPropertyNames files
    for name in list
      file = files[name]
      file.offset += offset
      end = file.offset + file.length
      throw 'read package error: padding mismatch' if buf[end] isnt pad_char
      file.data = buf.slice file.offset, end
      delete file.offset
    files
  # end of load cache package
  files:
    cache: path.join __dirname, 'cache.dat'
    path: path.join __dirname, 'public'
    regex: /^\/(favicon\.ico|client\.(?:html|js|css))(?:\?\d+)?$/ # no index.html
    client: 'client.html'
  prepare: (callback) ->
    fs.readFile @files.cache, 'binary', (err, data) =>
      throw err if err
      @cache = @_load_cache new Buffer data, 'binary'
      callback()
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
    else if req.url[-2..] is '!?'
      if Channel.ID_REGEX.test (id = req.url[1...-2])
        if Channel.has id
          res.writeHead 304, 'Not Modified'
        else
          Channel.create { id, io: @io }
          res.writeHead 201, 'Created'
      else
        res.writeHead 404, 'Not Found'
      res.end()
    else if Channel.ID_REGEX.test req.url
      # channel
      id = req.url[1..]
      Channel.create { id, io: @io } unless Channel.has id
      @serve { file: @files.client, caching: off, req, res }
    else if @files.regex.test req.url
      # static files
      file = req.url.match @files.regex
      # console.log 'routing file', req.url, file
      @serve { file: file[1], caching: on, req, res }
    else
      res.writeHead 404, 'Not Found'
      res.end '404 resource not found'
    return
  chkUA: (req, res) ->
    ua = req.headers['user-agent']
    if /MSIE [1-9]\./i.test ua
      msg = 'This WebApp does not support IE below 10!'
    else if /opera/i.test ua
      msg = 'This WebApp does not support Opera!'
    else if /^Mozilla\/4/i.test ua
      msg = 'This WebApp does not support your browser! \nIt seems your browser is out of date.'
    else
      return true
    # res.writeHead 200, 'Content-Type': 'text/plain'
    res.end msg
    return false
  
  MAX_AGE: 30 * 24 * 60 * 60 * 1000 # 30 days
  MIN_AGE: 60 * 1000 # 1 min
  serve: ({file, caching, req, res}) ->
    # console.log req.headers
    unless /\bgzip\b/.test req.headers['accept-encoding']
      console.log 'gzip unsupported for the client', file
      res.writeHead 406, 'Not Acceptable'
      res.end 'the client does not support gziped content.'
      return

    data = @cache[file]
    data.gz = data.data # rename
    data.mtime = new Date data.ts
    # if caching
    lastmod = req.headers['if-modified-since']
    etag = req.headers['if-none-match']
    if lastmod and etag and etag is data.etag and data.mtime is new Date(lastmod).getTime()
      console.log 'serve file not modified', file
      res.writeHead 304, 'Not Modified'
      res.end()
      return

    console.log 'serve file:', file, 'caching:', caching

    expires = if caching then data.mtime.getTime() + @MAX_AGE else new Date().getTime() + @MIN_AGE
    caching = if caching then @MAX_AGE else @MIN_AGE

    res.setHeader 'Content-Type', data.mime
    res.setHeader 'Content-Encoding', 'gzip'
    res.setHeader 'Vary', 'Accept-Encoding'
    res.setHeader 'Content-Length', data.gz.length
    res.setHeader 'Last-Modified', data.mtime.toUTCString()
    res.setHeader 'Date', new Date().toUTCString()
    res.setHeader 'Expires', new Date(expires).toUTCString()
    res.setHeader 'Cache-Control', 'public, max-age=' + (caching / 1000)
    res.setHeader 'ETag', "\"#{data.gz.length}-#{Date.parse data.mtime}\""
    res.end data.gz, 'binary'
    return

app = App.create()
