###
The fucking requirements
1. Compile coffee to js
2. Compile coffee to minified js
3. Compile stylus to css
4. Compile coffee to html
5. Move a directory
###

isLiteral = true

# Define build mode enumerable.
Mode = [
  'CoffeeToJS'
  'CoffeeToHtml'
  'StylusToCss'
]

for i in [0 .. Mode.length - 1]
  Mode[Mode[i]] = i

# Requirements
fs = require 'fs'
path = require 'path'
xcoffee = require 'extra-coffee-script'
coffeekup = require 'coffeekup'
stylus = require 'stylus'

compilers = []
compilers[Mode.CoffeeToJS] = (code, inPath, callback) ->
  setTimeout ->
    try
      output = xcoffee.compile code,
        imports: on
        filename: inPath
    catch error
      callback error

    callback undefined, output
  , 0
compilers[Mode.CoffeeToHtml] = (code, inPath, callback) ->
  setTimeout ->
    try
      output = coffeekup.render code
    catch error
      callback error

    callback undefined, output
  , 0
compilers[Mode.StylusToCss] = (code, inPath, callback) ->
  stylus.render code, callback

generalFilenameResolver = (filename, oldExt, newExt) ->
  unless /^\./.test oldExt then oldExt = '.' + oldExt
  unless /^\./.test newExt then newExt = '.' + newExt

  filanem = path.normalize filename
  dirname = path.dirname filename
  basename = path.basename filename, oldExt
  path.join dirname, basename + newExt

filenameResolvers = []
filenameResolvers[Mode.CoffeeToJS] = (filename) ->
  generalFilenameResolver filename, 'coffee', 'js'
filenameResolvers[Mode.CoffeeToHtml] = (filename) ->
  generalFilenameResolver filename, 'coffCoffee', 'html'
filenameResolvers[Mode.StylusToCss] = (filename) ->
  generalFilenameResolver filename, 'styl', 'css'

# Define the tasks here.
tasks = [
  [
    Mode.CoffeeToJS
    'src/app.coffee'
    'server/'
  ]
  [
    Mode.CoffeeToJS
    'src/scripts/client.coffee'
    'server/public/'
  ]
  [
    Mode.CoffeeToJS
    'src/modules/'
    'server/modules/'
  ]
  # [
  #   Mode.CoffeeToHtml
  #   'src/views/index.coffee'
  #   'server/public/'
  # ]
  # [
  #   Mode.StylusToCss
  #   'src/styles/client.styl'
  #   'server/public/'
  # ]
]

# Build a file.
buildFile = (mode, inAbsFile, outAbsFile) ->
  # Start to compile.
  fs.readFile inAbsFile, 'utf-8', (err, text) ->
    if err then throw err

    compilers[mode] text, inAbsFile, (err, code) ->
      if err then throw err

      fs.writeFile outAbsFile, code, 'utf-8', (err) ->
        if err then throw err

        if isLiteral
          console.log ''
          console.log "<#{inAbsFile}> is compiled to"
          console.log "  <#{outAbsFile}>"

# Build a list of files.
buildFiles = (mode, inAbsFiles, outAbsDir) ->  
  for inAbsFile in inAbsFiles
    # Append the filename to the path.
    inFilename = path.basename inAbsFile
    outFilename = filenameResolvers[mode] inFilename
    outAbsFile = path.join outAbsDir, outFilename

    buildFile mode, inAbsFile, outAbsFile

build = (mode, inRelatedPath, outRelatedDir) ->
  engine = compilers[mode]
  unless engine
    throw 'Build mode is not correct'

  inAbsPath = path.resolve __dirname, inRelatedPath
  stat = fs.statSync inAbsPath

  if stat.isFile()
    isFile = true
    inAbsFile = inAbsPath
  else if stat.isDirectory()
    isDir = true
    inAbsDir = inAbsPath
  else
    throw "The input path <#{inAbsPath}> is neither file or directory"
  
  outAbsDir = path.resolve __dirname, outRelatedDir

  if isFile
    buildFiles mode, [inAbsFile], outAbsDir
  else if isDir
    fs.readdir inAbsDir, (err, filenames) ->
      if err then throw err

      inAbsFiles = []
      for i in [0 .. filenames.length - 1]
        inAbsFile = path.join inAbsDir, filenames[i]

        stat = fs.statSync inAbsFile
        isFile = stat.isFile()

        if isFile then inAbsFiles.push inAbsFile

      buildFiles mode, inAbsFiles, outAbsDir

# Cakefile tasks.
task 'build', 'Build everything', ->
  for task in tasks
    build task[0], task[1], task[2]

task 'debug', 'Build in debug mode', ->
  console.log output = coffeekup.render code

task 'test', 'Run all test cases', ->