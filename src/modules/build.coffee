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

header = 'madtalk'

mkdir = (dir, callback) ->
  relative = path.relative __dirname, dir
  return unless relative
  relative = relative.split /[\\\/]/
  base = [__dirname]
  base.push relative.shift() while relative[0] is '..'
  base = path.resolve.apply path, base
  # console.log 'mkdir', base, relative
  if callback? # async
    do md = (relative, callback) ->
      if (r = relative.shift())
        base = path.join base, r
        path.exists base, (exists) -> unless exists
          fs.mkdir base, ->
            md relative, callback
      else
        callback? null
  else
    while (r = relative.shift())
      base = path.join base, r
      fs.mkdirSync base unless path.existsSync base
  return
# end of mkdir

rmdir = (dir, callback) ->
  if callback? # async
    path.exists dir, (exists) -> if exists
      fs.stat dir, (err, stat) ->
      if err then callback err
      unless stat.isDirectory() then callback "Path <#{dir}> is not a directory"
      path = path.resolve dir
      exec "rm -rf \"#{path}\"", (err, stdout, stderr) ->
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
    fs.writeFileSync targetFile, fs.readFileSync sourceFile
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
  if callback? # async (callback is not func means no callback)
    fs.readdir (err, files) ->
      throw err if err
      for name in files
        src = path.join sourceDir, name
        des = path.join targetDir, name
        srcStats = fs.statSync src
        # temp use sync for sub items
        if srcStats.isDirectory()
          cpdir src, des#, true
        else
          cpfile src, des#, true
      callback?()
  else # sync
    files = fs.readdirSync sourceDir

    for name in files
      src = path.join sourceDir, name
      srcStats = fs.statSync src
      des = path.join targetDir, name

      if srcStats.isDirectory()
        cpdir src, des
      else
        cpfile src, des
  return
# end of cpdir

write = (filename, data, {encoding, withgz, callback} = {}) ->
  throw 'need filename and data' unless filename and data
  callback = cb if not callback? and typeof (cb = arguments[arguments.length - 1]) is 'function'
  if callback? # async (callback is not func means no callback)
    fs.writeFile filename, data, encoding, (err) ->
      callback? err
    if withgz then fs.writeFile filename + '.gz', (gzip new Buffer data, 9), 'binary'
  else
    fs.writeFileSync filename, data, encoding
    if withgz then fs.writeFileSync filename + '.gz', (gzip new Buffer data, 9), 'binary'
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
  stylus: _stylus
}
