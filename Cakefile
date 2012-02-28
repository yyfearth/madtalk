# Requirements & definition
fs = require 'fs'
path = require 'path'
xcoffee = require 'extra-coffee-script'
coffeekup = require 'coffeekup'
stylus = require 'stylus'
uglifyjs = require 'uglify-js'
util = require 'util'
fileIO = require './fileIO.coffee'

minifyJs = (code, cb) ->
  setTimeout(->
    try
      jsp = uglifyjs.parser
      pro = uglifyjs.uglify

      ast = jsp.parse code
      ast = pro.ast_mangle ast
      ast = pro.ast_squeeze ast
      code = pro.gen_code ast
    catch err
      cb err

    cb undefined, code
  , 0)

stylusToCss = (args, cb = ->) ->  
  console.log "Compiling <#{args.from}> to <#{args.to}>"

  inFile = path.resolve __dirname, args.from
  outFile = path.resolve __dirname, args.to
  outDir = path.dirname outFile

  console.log inFile
  console.log outFile

  fs.readFile inFile, (err, code) ->
    if err?
      cb err
      return

    stylus.render code, {filename: inFile}, (err, code) ->
      if err?
        cb err
        return

      fileIO.makeDirSync outDir
      fs.writeFile outFile, code, 'utf-8', (err) ->
        if err?
          cb err
          return

        cb undefined

copyDir = (srcDir, targetDir, cb) ->
  setTimeout(->
    fileIO.copyDirSync srcDir, targetDir
    if typeof cb is 'function' then cb()
  ,0)

_coffeeToJs = (code, importBasefile, isMinified = false, cb) ->
  setTimeout(->
    if typeof importBasefile is 'function'
      callback = importBasefile
    else    
      isImport = typeof importBasefile is 'string'

    try
      code = xcoffee.compile code,
        imports: isImport
        filename: importBasefile
    catch err
      cb err

    if isMinified
      minifyJs code, (err, code) ->
        if err?
          cb err
          return

        cb undefined, code
    else
      cb undefined, code
  , 0)

oneCoffeeToJs = (args, cb = ->) ->
  console.log "Compiling <#{args.from}> to <#{args.to}>"

  inFile = path.resolve __dirname, args.from
  outFile = path.resolve __dirname, args.to
  outDir = path.dirname outFile

  # Since minification consumes a lot of CPU, I don't override it if the file exists.
  if args.isMinified and fileIO.isFileSync(outFile)
    console.log "File <#{args.to}> exists"
    cb undefined
    return

  write = (outFile, code, cb) ->
    fs.writeFile outFile, code, 'utf-8', (err) ->
      cb err

  fs.readFile inFile, 'utf-8', (err, code) ->
    _coffeeToJs code, inFile, args.isMinified, (err, code) ->
      if err?
        cb err
        return

      path.exists outFile, (doesExist) ->
        if doesExist
          fs.stat outFile, (err, stats) ->
            if err?
              cb err
              return

            if stats.isDirectory()
              fileIO.deleteDirSync outFile

            write outFile, code, cb
        else
          fileIO.makeDirSync outDir
          write outFile, code, cb

multiCoffeeToJs = (args, cb = ->) ->
  console.log "Compiling <#{args.from + '*'}> to <#{args.to + '*'}>"

  inDir = path.resolve __dirname, args.from
  outDir = path.resolve __dirname, args.to

  if path.existsSync outDir
    if (fs.statSync outDir).isFile()
      fs.unlinkSync filePath = outDir
  else
    fileIO.makeDirSync task.outAbsDir

  fs.readdir inDir, (err, names) ->
    if err?
      cb err
      return

    errors = []
    count = 0

    callback = (err) ->
      if err?
        errors.push err

      if --count <= 0
        cb if errors.length == 0 then undefined else errors
    
    for name in names
      ext = path.extname name

      if ext != '.coffee'
        break
      
      ++count

      inFile = path.join inDir, name
      outFile = path.join outDir, replaceExtension name, 'coffee', 'js'

      oneCoffeeToJs {
        from: inFile
        to: outFile
        isMinified: args.isMinified
      }, callback

coffeeToJs = (args, cb) ->
  act = (inFile, outFile) ->
    code = fs.readFileSync inFile, 'utf-8'
    code = coffeeToJs code, inFile

    console.log "Compiling <#{inFile}> to <#{outFile}>"

    if path.existsSync outFile
      if (fs.statSync outFile).isDirectory()
        fileIO.deleteDirSync outFile
    else
      fileIO.makeDirSync task.outAbsDir

    fs.writeFileSync outFile, code, 'utf-8'

  if task.inAbsFile?
    act task.inAbsFile, task.outAbsFile
  else
    for i in [0 .. task.inFiles.length - 1]
      act task.inFiles[i], task.outFiles[i]

  if typeof cb is 'function' then cb()

coffeeToJs = (args, cb = ->) ->
  fileIO.isFile args.from, (err, isFile) ->
    if err
      cb err
      return

    if isFile
      oneCoffeeToJs args, cb
      return

    fileIO.isDir args.from, (err, isDir) ->
      if err
        cb err
        return

      if isDir
        multiCoffeeToJs args, cb

replaceExtension = (filename, oldExt, newExt) ->
  unless /^\./.test oldExt then oldExt = '.' + oldExt
  unless /^\./.test newExt then newExt = '.' + newExt

  filanem = path.normalize filename
  dirname = path.dirname filename
  basename = path.basename filename, oldExt
  path.join dirname, basename + newExt

resolveFilename = (action, task) ->
  console.log '> Resolve: ', action, 'with', task
  switch action
    when 'CoffeeToJS'
      outName = replaceExtension task.inName, 'coffee', if task.isMinified then 'min.js' else 'js'
    when 'StylusToCss'
      outName = replaceExtension task.inName, 'styl', 'css'
    else
      outName = task.inName
  console.log 'outName', outName
  outName
      
analysisTask = (task) ->
  inAbsPath = path.resolve __dirname, task.in
  task.outAbsDir = outAbsPath = path.resolve __dirname, task.out
  stat = fs.statSync inAbsPath

  if stat.isFile()
    task.inAbsFile = inAbsPath
    task.inName = path.basename task.inAbsFile
    task.outName = resolveFilename task
    task.outAbsFile = path.join outAbsPath, task.outName
  else if stat.isDirectory()
    task.inNames = fs.readdirSync inAbsPath
    task.inFiles = []
    task.outFiles = []
    task.outNames = []
    task.inNames.forEach (inName, index) ->
      task.inFiles[index] = path.join inAbsPath, inName
      task.outNames[index] = outName = resolveFilename task
      task.outFiles[index] = path.join task.outAbsDir, outName

task 'build', 'Build everything', ->
  copyDir 'src/public/', 'server/public'

  coffeeToJs {
    from: 'src/modules/'
    to: 'server/modules/'    
  }

  coffeeToJs {
    from: 'src/scripts/client.coffee'
    to: 'server/public/client.min.js'
    isMinified: yes
  }

  # stylusToCss {
  #   from: 'src/styles/client.styl'
  #   to: 'server/public/client.css'
  #   isMinified: yes
  # }

  # coffeeToHtml {
  #   from: 'src/views/index.coffee'
  #   to: 'server/public/index.html'
  #   isMinified: yes
  # }

task 'test', 'Run all test cases', ->
