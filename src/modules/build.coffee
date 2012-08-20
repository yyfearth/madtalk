# build tool set

path = require 'path'
fs = require 'fs'
{exec} = require 'child_process'
async = require 'async'
zlib = require 'zlib'
xcoffee = require 'extra-coffee-script'
coffeekup = require 'coffeekup'
stylus = require 'stylus'
{cssmin} = require 'cssmin'
exists = fs.exists or path.exists
existsSync = fs.existsSync or path.existsSync
#nib = require 'nib'

HEADER = 'madtalk - yyfearth.com/myyapps.com'

mkdir = (dir, callback) ->
  # console.log 'mkdir', base, _rel
  if callback? # async
    dir = path.resolve dir
    exec "mkdir -p \"#{dir}\"", (err, stdout, stderr) ->
      callback stderr if stderr
      console.log err if err
      unless err
        callback?()
        return
      # fallback use sync
      # mkdir dir
      # callback?()
      throw 'err'
  else
    _rel = path.relative __dirname, dir
    return unless _rel
    _rel = _rel.split /[\\\/]/
    base = [__dirname]
    base.push _rel.shift() while _rel[0] is '..'
    base = path.resolve.apply null, base
    while (r = _rel.shift())
      base = path.join base, r
      fs.mkdirSync base unless existsSync base
  return
# end of mkdir

rmdir = (dir, callback) ->
  if callback? # async
    exists dir, (exists) ->
      unless exists
        callback?()
        return
      fs.stat dir, (err, stat) ->
        if err then callback err
        unless stat.isDirectory() then callback "Path <#{dir}> is not a directory"
        dir = path.resolve dir
        console.log 'clean:', dir
        exec "rm -rf \"#{dir}\"", (err, stdout, stderr) ->
          callback stderr if stderr
          unless err
            callback?()
            return
          rmdir dir # fallback
  else # sync
    unless existsSync dir
      # console.log 'Directory <#{dir}> does not exist'
      return false
    
    stat = fs.statSync dir
    unless stat.isDirectory() then callback "Path <#{dir}> is not a directory"

    do act = (dir) ->
      names = fs.readdirSync dir

      for name in names
        filePath = path.join dir, name

        do (filePath) ->
          stat = fs.statSync filePath

          if stat.isFile()
            # console.log "Delete #{filePath}"
            fs.unlinkSync filePath
          else if stat.isDirectory()
            act filePath

      # console.log "Remove #{dir}"
      fs.rmdirSync dir
  return
# end of rmdir

cpdir = (from, to, callback) ->
  # do not copy sub dirs for now
  fs.readdir from, (err, files) ->
    throw err if err
    async.map files, (name, callback) ->
      if name[0] is '.'
        callback null
        return
      # console.log 'find', name
      src = path.join from, name
      fs.stat src, (err, stats) ->
        if stats.isDirectory()
          # console.log 'is dir', name
          callback null
        else
          console.log 'copy file', name
          fs.readFile src, 'binary', (err, data) ->
            # console.log 'read', data.length
            des = path.join to, name
            write des, data,
              encoding: 'binary'
              callback: -> callback null,
                filename: name
                data: new Buffer data, 'binary'
        return
    , (err, data) ->
      callback? err, data
  return
# end of cpdir

gzdir = (files, callback) ->
  async.forEach files, (f, c) ->
    throw 'file.data is not a buffer' unless Buffer.isBuffer f.data
    f.size = f.data.length
    zlib.gzip f.data, (err, gz_data) ->
      if gz_data.length < f.data.length
        f.data = gz_data
        f.gz = 1
      else f.gz = 0
      c()
  , (err) -> callback? err, files
  return
# end of gzdir

add_header = (filename, data, header = HEADER) ->
  ext = (path.extname filename)[1..].toLowerCase()
  switch ext
    when 'css', 'js'
      return "/*! #{header} */\n#{data}\n"
    when 'html'
      return "#{data}<!-- #{header} -->\n"
    else
      return data
# end of add header

write = (filename, data, {encoding, callback} = {}) ->
  # console.log filename, data.length
  throw 'need filename and data' unless filename and data
  callback = cb if not callback? and typeof (cb = arguments[arguments.length - 1]) is 'function'
  # default encoding is urf-8
  if callback? # async (callback is not func means no callback)
    fs.writeFile filename, data, encoding, (err) ->
      callback? err
  else
    fs.writeFileSync filename, data, encoding
  return
# end of write

load_pkg = (buf) ->
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
# end of load package

mime_dict =
  js  : 'application/javascript;charset=utf-8'
  json: 'application/json;charset=utf-8'
  html: 'text/html;charset=utf-8'
  xml : 'text/xml;charset=utf-8'
  xsl : 'text/xml'
  xsd : 'text/xml'
  css : 'text/css'
  txt : 'text/plain'
  png : 'image/png'
  jpg : 'image/jpeg'
  gif : 'image/gif'
  ico : 'image/x-icon'
  bmp : 'image/x-ms-bmp'
  mp3 : 'audio/mpeg'
  ogg : 'audio/ogg'
  wav : 'audio/x-wav'
  appcache: 'text/cache-manifest'
  0: 'application/octet-stream' # default

mime_dict.jpeg = mime_dict.jpg
mime_dict.htm = mime_dict.html

# end of mime_dict

get_mime_name = (filename) ->
  ext = (path.extname filename)[1..].toLowerCase()
  if mime_dict.hasOwnProperty ext then ext else 0

get_mime = (filename) ->
  ext = path.extname filename
  mime_dict[ext[1..].toLowerCase()]

build_pkg = (files, {filename, callback} = {}) ->
  if typeof files is 'string' # a dir path is given
    files = lsdirSync files
    readdirgz files, (err, files) ->
      if err
        throw err unless callback?
        callback err
      else
        build_pkg files, {filename, callback}
    return
  throw 'no files' unless files?[0]?.filename
  head = v: 2, ts: new Date().getTime(), files: {}
  buffer = null
  buf_size = 0
  pad_len = 16
  pad_char = 0
  # files = [ {filename: '', mime: '', size: 0, data: Buffer} ]
  files.forEach (file) ->
    throw 'data should be a buffer' unless file.data and Buffer.isBuffer file.data
    
    len = file.data.length
    mime = file.mime or get_mime file.filename # 0 for not found

    # head.files[file.filename.toLowerCase()] = # case insensitive
    head.files[file.filename] = # case sensitive
      filename: file.filename
      mime: file.mime or get_mime file.filename
      gz: file.gz
      offset: buf_size
      length: len # gz length
      size: file.size # orginal size
      mtime: file.mtime
    
    buf_size += pad_len + len

  head_buf = new Buffer (JSON.stringify head), 'utf-8'
  head_len = head_buf.length
  buf_size += head_len + 2 # buffer_size already contain an extra pad_len
  buffer = new Buffer buf_size
  # fill buffer
  buffer.fill pad_char # fill pad_char to all
  cur_pos = 1
  # set head to the start (2rd char) of buffer
  head_buf.copy buffer, cur_pos
  cur_pos += head_len
  # set data to buffer with padding
  files.forEach (file) ->
    cur_pos += pad_len
    file.data.copy buffer, cur_pos
    cur_pos += file.data.length
    return
  # end of set buffer
  if filename
    if callback? # async (callback is not func means no callback)
      fs.writeFile filename, buffer, 'binary', (err) ->
        callback? err
    else
      fs.writeFileSync filename, buffer, 'binary'
  buffer # return
# end of build package

_coffee = (filename, {minify, callback} = {}) ->
  throw 'need filename' unless filename
  callback = cb if not callback? and typeof (cb = arguments[arguments.length - 1]) is 'function'
  code = "import \"#{path.basename filename, '.coffee'}\""
  opt =
    filename: path.resolve filename
    imports: on
    # header: header
    minify: minify ? off
  if callback? # async (callback is not func means no callback)
    async.nextTick -> callback? xcoffee.compile code, opt
    return
  else
    xcoffee.compile code, opt
# end of build coffee
_coffeekup = (filename, options = {}, callback) ->
  throw 'need filename' unless filename
  callback = cb if not callback? and typeof (cb = options.callback or options) is 'function'
  basedir = (path.join (path.dirname filename), '_')[0...-1]
  options.ts ?= new Date().getTime()
  options.partial ?= (name) ->
    data = fs.readFileSync basedir + name + '.coffee', 'utf-8'
    coffeekup.render data, options
  options.hardcode ?= {}
  options.hardcode.partial = (view) -> text @partial view
  # end of hardcode partial
  if callback? # async (callback is not func means no callback)
    do (filename, basedir, options) ->
      _layout = _body = null
      _parallel = (layout, body) ->
        _layout ?= layout
        _body ?= body
        if _layout and _body
          options.body = _body
          callback? coffeekup.render _layout, options
      fs.readFile basedir + 'layout.coffee', 'utf-8', (err, data) ->
        throw err if err
        _parallel data
      fs.readFile filename, 'utf-8', (err, body) ->
        throw err if err
        _parallel null, coffeekup.render body, options
    return
  else
    layout = fs.readFileSync basedir + 'layout.coffee', 'utf-8'
    body = fs.readFileSync filename, 'utf-8'
    options.body = coffeekup.render body, options
    coffeekup.render layout, options
# end of coffeekup
_stylus = (filename, {compress, paths, callback} = {}) ->
  callback = cb if not callback? and typeof (cb = arguments[arguments.length - 1]) is 'function'
  throw 'need filename and callback' unless filename and typeof callback is 'function'
  stylus.render "@import \"#{path.basename filename, '.styl'}\"", 
    #filename: filename
    paths: paths ? [(path.dirname path.resolve filename), __dirname]
    compress: compress ? on
  , (err, css) ->
    throw err if err
    if /^mini?f?y?$/i.test compress
      async.nextTick ->
        callback cssmin css
    else
      callback css
  return
# end of build stylus

module.exports = {
  async
  mkdir
  rmdir
  gzdir
  write
  cpdir
  add_header
  coffee: _coffee
  coffeekup: _coffeekup
  stylus: _stylus
  load_pkg
  build_pkg
}
