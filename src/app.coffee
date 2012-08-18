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
    head_len = 1
    pad_len = 16
    pad_char = 0
    head_len++ while buf[head_len]
    head = buf.toString 'utf-8', 1, head_len
    throw 'read package error: format padding mismatch' unless buf[0] is buf[buf.length - 1] is pad_char
    try
      head = JSON.parse head
    catch e
      throw 'cannot parse package'
    throw 'unacceptable package version ' + head.v unless head.v is 2
    offset = head_len + pad_len
    # test padding
    throw 'read package error: head padding mismatch' if buf[offset - 1] isnt pad_char
    # load content
    _get_data = (file) ->
      file.offset += offset
      end = file.offset + file.length
      throw 'read package error: padding mismatch' if buf[end] isnt pad_char
      file.data = buf.slice file.offset, end
      delete file.offset
      return
    files = head.files
    _get_data files[name] for name in Object.getOwnPropertyNames files
    # end of if is array
    files
  # end of load cache package
  files:
    cache: path.join __dirname, 'cache.dat'
    path: path.join __dirname, 'public'
    regex:  /^\/(\w+\.(?:ico|js|css|html|png))(?:\?\d+)?$/ # /^\/(favicon\.ico|client\.(?:html|js|css))(?:\?\d+)?$/ # no index.html
    client: 'client.html'
  prepare: (callback) ->
    fs.readFile @files.cache, 'binary', (err, data) =>
      throw err if err
      @cache = @_load_cache new Buffer data, 'binary'
      console.log 'cache loaded'
      callback()
      return
  routing: (req, res) ->
    return unless (@chkUA req, res) and (@_chk_gz req, res)
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
    else
      file = req.url.match @files.regex
      if file?[1] and @cache[file[1]]
        # static files
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

  _chk_gz: (req, res) ->
    unless /\bgzip\b/.test req.headers['accept-encoding']
      console.log 'gzip unsupported for the client'
      res.writeHead 406, 'Not Acceptable'
      res.end 'the client does not support gziped content (accept-encoding header).'
      false
    else true
  # end of check gz support
  _chk_mod: (url, file, req, res) ->
    _lastmod = req.headers['if-modified-since']
    _etag = req.headers['if-none-match']
    if _lastmod and _etag and _etag is file._etag and file.mtime is new Date(_lastmod).getTime()
      console.log '304 served file not modified', url
      res.writeHead 304, 'Not Modified'
      res.end()
      false
    else true
  # end of check if modified
  serve: ({url, file, caching, req, res}) ->
    # console.log req.headers
    console.log 'req:', req.connection.remoteAddress, req.url

    unless _file = @cache[file]
      throw 'failed to find the file ' + file

    _file._mtime ?= new Date _file.mtime
    _file._etag ?= "\"#{_file.size}-#{_file.mtime}\""

    return unless @_chk_mod url, _file, req, res

    console.log '200 serve file:', file # , 'caching:', caching

    _expires = if caching then _file.mtime + @MAX_AGE else new Date().getTime() + @MIN_AGE
    _caching = if caching then @MAX_AGE else @MIN_AGE

    # for IE6 do not use 'Cache-Control: no-cache'
    res.setHeader 'Content-Type', _file.mime
    res.setHeader 'Content-Encoding', 'gzip' if _file.gz
    res.setHeader 'Vary', 'Accept-Encoding'
    res.setHeader 'Content-Length', _file.data.length
    res.setHeader 'Last-Modified', _file._mtime.toUTCString()
    res.setHeader 'Date', new Date().toUTCString()
    res.setHeader 'Expires', new Date(_expires).toUTCString()
    res.setHeader 'Cache-Control', 'public, max-age=' + (_caching / 1000) | 0
    res.setHeader 'ETag', _file._etag
    res.end _file.data, 'binary'

    return
  # end of serve file

app = App.create()
