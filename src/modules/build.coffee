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

cpdirgz = (from, to, callback) ->
  # do not copy sub dirs for now
  fs.readdir from, (err, files) ->
    throw err if err
    async.forEach files, (name, callback) ->
      # console.log 'find', name
      src = path.join from, name
      fs.stat src, (err, stats) ->
        if stats.isDirectory()
          # console.log 'is dir', name
          callback()
        else
          console.log 'copy file', name
          fs.readFile src, 'binary', (err, data) ->
            # console.log 'read', data.length
            des = path.join to, name
            write des, data,
              encoding: 'binary'
              withgz: on
              callback: callback
        return
    , -> callback?()
  return
# end of cpdirgz

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
  # default encoding is urf-8
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
  write
  cpdirgz
  coffee: _coffee
  coffeekup: _coffeekup
  stylus: _stylus
}
