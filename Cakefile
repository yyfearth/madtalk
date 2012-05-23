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

_data = (outpath, data) ->
  filename: path.basename outpath
  data: new Buffer data, 'utf-8'

coffee = (filename, client = no, callback) ->
  console.log 'start', filename
  outpath = _out_path client, _base_ext filename, '.coffee', '.js'
  build.coffee (_src_path filename), minify: client, callback: (js) ->
    console.log 'compiled', filename, '->', path.basename outpath
    js = build.add_header outpath, js
    build.write outpath, js, callback: ->
      console.log 'wrote', outpath
      callback? null, unless client then null else _data outpath, js
  return
stylus = (filename, callback) ->
  console.log 'start', filename
  outpath = _client_path _base_ext filename, '.styl', '.css'
  build.stylus (_src_path filename), compress: 'minify', callback: (css) ->
    console.log 'compiled', filename, '->', path.basename outpath
    css = build.add_header outpath, css
    build.write outpath, css, callback: ->
      console.log 'wrote', outpath
      callback? null, _data outpath, css
  return
coffeekup = (filename, callback) ->
  console.log 'start', filename
  outpath = _client_path _base_ext filename, '.coffee', '.html'
  build.coffeekup (_src_path filename), (html) ->
    console.log 'compiled', filename, '->', path.basename outpath
    html = build.add_header outpath, html
    build.write outpath, html, callback: ->
      console.log 'wrote', outpath
      callback? null, _data outpath, html
  return


task 'build', 'Build everything to ./server/', ->
  build.rmdir (_server_path '.'), (err) ->
    throw err if err
    console.log 'output dir cleaned'
    # build.mkdir _server_path '.'
    build.mkdir (cl = _client_path '.'), ->
      console.log 'start copy static files'
      build.cpdir (_src_path 'public'), cl, (err, dir_files) ->
        console.log 'static files copied'
        async.parallel [
          (callback) -> stylus 'styles/client.styl', callback
          (callback) -> coffeekup 'views/client.coffee', callback
          (callback) -> coffee 'app.coffee', no, callback
          (callback) -> coffee 'scripts/client.coffee', yes, callback
        ], (err, files) ->
          if err
            console.error 'build failed', err
          else
            # console.log files
            files = (files.concat dir_files).filter (f) -> f?.data
            build.gzdir files, (err, files) ->
              throw err if err
              # console.log files
              build.build_pkg files,
                filename: _server_path 'cache.dat'
                callback: ->
                  console.log 'cache data created'
                  console.log 'build done'
              # console.log 'pkg\n', build.load_pkg pkg

task 'build:server', 'Build everything to ./server/', ->
  build.mkdir _server_path '.'
  coffee 'app.coffee', no, (err) ->
    if err
      console.error 'build failed', err
    else
      console.log 'build done'

# task 'test', 'Run all test cases', ->
