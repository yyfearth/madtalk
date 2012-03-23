# Requirements & definition
fs = require 'fs'
path = require 'path'
util = require 'util'
build = require './src/modules/build'
async = build.async

_base_ext = (filepath, from, to) -> (path.basename filepath, from) + to
_src_path = (f...) -> path.resolve __dirname, 'src', f...
_server_path = (f...) -> path.resolve __dirname, 'server', f...
_client_path = (f...) -> path.resolve __dirname, 'server', 'public', f...
_out_path = (client, f...) ->
  if client
    _client_path f...
  else
    _server_path f...

coffee = (filename, client = no, callback) ->
  console.log 'start', filename
  outpath = _out_path client, _base_ext filename, '.coffee', '.js'
  build.coffee (_src_path filename), minify: client, callback: (js) ->
    console.log 'compiled', filename, '->', path.basename outpath
    build.write outpath, js, withgz: client, callback: ->
      console.log 'wrote', outpath
      callback? null
  return
stylus = (filename, callback) ->
  console.log 'start', filename
  outpath = _client_path _base_ext filename, '.styl', '.css'
  build.stylus (_src_path filename), compress: 'minify', callback: (css) ->
    console.log 'compiled', filename, '->', path.basename outpath
    build.write outpath, css, withgz: on, callback: ->
        console.log 'wrote', outpath
        callback? null
  return
coffeekup = (filename, callback) ->
  console.log 'start', filename
  outpath = _client_path _base_ext filename, '.coffee', '.html'
  build.coffeekup (_src_path filename), (html) ->
    console.log 'compiled', filename, '->', path.basename outpath
    build.write outpath, html, withgz: on, callback: ->
      console.log 'wrote', outpath
      callback? null
  return


task 'build', 'Build everything to ./server/', ->
  build.rmdir (_server_path '.'), (err) ->
    throw err if err
    console.log 'output dir cleared'
    # build.mkdir _server_path '.'
    build.mkdir (cl = _client_path '.')
    console.log 'start copy static files'
    build.cpdirgz (_src_path 'public'), cl, ->
      console.log 'static files copied'
      async.parallel [
        (callback) -> stylus 'styles/client.styl', callback
        (callback) -> coffeekup 'views/client.coffee', callback
        (callback) -> coffee 'app.coffee', no, callback
        (callback) -> coffee 'scripts/client.coffee', yes, callback
      ], (err) ->
        if err
          console.error 'build failed', err
        else
          console.log 'build done'

task 'build:server', 'Build everything to ./server/', ->
  build.mkdir _server_path '.'
  coffee 'app.coffee', no, (err) ->
    if err
      console.error 'build failed', err
    else
      console.log 'build done'


# task 'test', 'Run all test cases', ->
