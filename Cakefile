{exec} = require 'child_process'
fs = require 'fs'
path = require 'path'
xcoffee = require 'extra-coffee-script'

task 'build', 'Build everything', ->
	srcPath = path.resolve __dirname, 'src', 'app.coffee'
	code = fs.readFileSync srcPath, 'utf-8'
	compiledCode = xcoffee.compile code, filename: srcPath
	outPath = path.resolve __dirname, 'server', 'app.js'
	fs.writeFileSync outPath, compiledCode, 'utf-8'
