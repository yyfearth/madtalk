# madtalk client.coffee

import './class/Login'

channel = io.connect '/0'

try
  user = sessionStorage.user
  if user
    user = JSON.parse user
    throw 'bad user session data' unless user?.nick
  else
    user = null
catch e
  console.error 'bad user session data', e
  user = null

_log = null
add_log = (recs) ->
  recs = [recs] unless Array.isArray recs
  recs = recs.map (rec) ->
    "<li>#{new Date(rec.ts).toLocaleTimeString()} #{rec.user.nick} - #{rec.data}</li>"
  
  _log.append recs.join '\n'
  return

do_login = (user) ->
  console.log 'do_login', user
  channel.emit 'login', user, (upduser, records) -> # updated user profile

    if upduser.err
      console.error upduser
    else
      console.log 'logined', upduser
      user.uid = upduser.uid

      channel.el = document.querySelector '#channel'
      channel.el.hidden = false
      # show

      channel.on 'online', (user) ->
        console.log 'online', user

      channel.on 'offline', (user) ->
        console.log 'offline', user

      channel.on 'message', (data) ->
        console.log 'got message', data
        add_log data

      channel.message = (data) ->
        channel.emit 'message', data, (ok) ->
          if ok
            console.log 'message sent', data
          else
            console.error data

      window.onbeforeunload = ->
        sessionStorage.user = JSON.stringify user
        'sure to exit?'

      $('#entry').keydown (e) ->
        if e.keyCode is 13 and not (e.ctrlKey or e.metaKey or e.shiftKey or e.altKey)
          channel.message type: 'text', data: @value
          @value = ''
          false

      _log.empty()
      add_log records

      return
    # end of emit login
  return

login = new Login el: '#login', user: user, logined: do_login

window.channel = channel

channel.on 'connect', ->
  console.log 'connected'
  $ -> # dom ready, todo: wait for conn
    console.log 'domready'
    $('#conn-status').text 'online'

    _log = $ '#log'

    channel.on 'system', (data) ->
      console.log 'got system message', data

    login.init() unless login.inited

channel.on 'disconnect', ->
  $('#conn-status').text 'offline'
