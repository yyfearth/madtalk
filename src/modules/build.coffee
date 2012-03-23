# build tool set

path = require 'path'
fs = require 'fs'
{exec} = require 'child_process'
async = require 'async'
{compress: gzip} = require 'compress-buffer'
xcoffee = require 'extra-coffee-script'
coffeekup = require 'coffeekup'
stylus = require 'stylus'
{cssmin} = require 'cssmin'
#nib = require 'nib'

header = 'madtalk - yyfearth.com/myyapps.com'

mkdir = (dir, callback) ->
  # console.log 'mkdir', base, _rel
  if callback? # async
    dir = dir.resolve dir
    exec "mkdir -p \"#{path}\"", (err, stdout, stderr) ->
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
    base = path.resolve.apply path, base
    while (r = _rel.shift())
      base = path.join base, r
      fs.mkdirSync base unless path.existsSync base
  return
# end of mkdir

rmdir = (dir, callback) ->
  if callback? # async
    path.exists dir, (exists) ->
      unless exists
        callback?()
        return
      fs.stat dir, (err, stat) ->
        if err then callback err
        unless stat.isDirectory() then callback "Path <#{dir}> is not a directory"
        dir = path.resolve dir
        console.log 'rm -rf:', dir
        exec "rm -rf \"#{dir}\"", (err, stdout, stderr) ->
          callback stderr if stderr
          unless err
            callback?()
            return
          rmdir dir # fallback
  else # sync
    unless path.existsSync dir
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

cpfile = (from, to, callback) -> # from, to must be filename not dirname
  if callback? # async (callback is not func means no callback)
    from = fs.createWriteStream from
    to = fs.createReadStream to
    to.once 'open', (fd) ->
      util.pump from, to
      callback?()
  else
    # @makeDirSync path.dirname targetFile
    fs.writeFileSync to, fs.readFileSync from
    # log "Copy <#{sourceFile}> to <#{targetFile}>"
    # with buffer
    # BUF_LENGTH = 64*1024
    # buff = new Buffer BUF_LENGTH
    # fdr = fs.openSync srcFile, 'r'
    # fdw = fs.openSync destFile, 'w'
    # bytesRead = 1
    # pos = 0
    # while bytesRead > 0
    #   bytesRead = fs.readSync fdr, buff, 0, BUF_LENGTH, pos
    #   fs.writeSync fdw,buff,0,bytesRead
    #   pos += bytesRead
    # fs.closeSync fdr
    # fs.closeSync fdw
  return
# end of copy

cpdir = (from, to, callback) ->
  # do not copy sub dirs for now
  if callback? # async (callback is not func means no callback)
    fs.readdir from, (err, files) ->
      throw err if err
      async.forEach files, (name, callback) ->
        src = path.join from, name
        des = path.join to, name
        fs.stat src, (err, stats) ->
          cpfile src, des, callback unless stats.isDirectory()
          return
      , -> callback?()
  else # sync
    files = fs.readdirSync from

    for name in files
      src = path.join from, name
      srcStats = fs.statSync src
      des = path.join to, name

      cpfile src, des unless srcStats.isDirectory()
  return
# cpdir = (from, to, callback) ->
#   if callback? # async (callback is not func means no callback)
#     fs.readdir (err, files) ->
#       throw err if err
#       for name in files
#         src = path.join from, name
#         des = path.join to, name
#         srcStats = fs.statSync src
#         # temp use sync for sub items
#         if srcStats.isDirectory()
#           cpdir src, des#, true
#         else
#           cpfile src, des#, true
#       callback?()
#   else # sync
#     files = fs.readdirSync sourceDir

#     for name in files
#       src = path.join from, name
#       srcStats = fs.to src
#       des = path.join targetDir, name

#       if srcStats.isDirectory()
#         cpdir src, des
#       else
#         cpfile src, des
#   return
# end of cpdir

write = (filename, data, {encoding, withgz, callback} = {}) ->
  throw 'need filename and data' unless filename and data
  callback = cb if not callback? and typeof (cb = arguments[arguments.length - 1]) is 'function'
  ext = (path.extname filename)[1..].toLowerCase()
  if /^(?:j|cs)s$/.test ext
    data = "/*! #{header} */#{data}\n"
  else if /^html?$/.test ext
    data = "#{data}<!-- #{header} -->\n"
  else
    data += '\n'
  if callback? # async (callback is not func means no callback)
    fs.writeFile filename, data, encoding, (err) ->
      callback? err
    if withgz then fs.writeFile filename + '.gz', (gzip (new Buffer data), 9), 'binary'
  else
    fs.writeFileSync filename, data, encoding
    if withgz then fs.writeFileSync filename + '.gz', (gzip (new Buffer data), 9), 'binary'
  return
# end of write

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
  callback = cb if not callback? and typeof (cb = options.callback) is 'function'
  basedir = (path.join (path.dirname filename), '_')[0...-1]
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
    options.ts ?= new Date().getTime()
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
  cpfile
  cpdir
  mkdir
  rmdir
  write
  coffee: _coffee
  coffeekup: _coffeekup
  stylus: _stylus
}
