# madtalk client.coffee

import 'login'
import 'xss_safe'

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
_users = null
_toolbar = null
gfm = new Showdown.converter()

add_log = (recs) ->
  recs = [recs] unless Array.isArray recs
  # gfm.makeHtml xss_safe.str(rec.data).replace /\n/g, '<br/>'
  recs = recs.map (rec) -> "<li>
<label>#{xss_safe.str rec.user.nick}<br/>
#{new Date(rec.ts).toLocaleTimeString()}</label>
<div>#{gfm.makeHtml xss_safe.str rec.data}</div>
</li>"
  
  _log.append recs.join '\n'
  _log.css 'padding-bottom', _toolbar.outerHeight() + 10 + 'px' # log resize

  #window.scrollBy 0, _log.outerHeight()
  setTimeout ->
    window.scrollTo 0, document.body.scrollHeight
  , 0

  return

do_login = (user) ->
  console.log 'do_login', user
  channel.emit 'login', user, (upduser, ch) -> # updated user profile

    if upduser.err
      console.error upduser
      alert upduser.err + '\n reload the app pls!'
    else
      console.log 'logined', upduser, ch
      user.uid = upduser.uid

      channel.records = ch.records or []
      users = channel.users = ch.users # included me
      channel.ts = ch.ts
      users.index = {}
      users.forEach (u) -> users.index[u.nick] = u

      channel.el = document.querySelector '#channel'
      channel.el.hidden = false
      # show

      channel.on 'online', (user) ->
        console.log 'online', user
        users.push user unless users.index[user.nick]?
        users.index[user.nick].status is 'online'
        _log.append "<li>#{user.nick} Online</li>"

      channel.on 'offline', (user) ->
        users.index[user.nick].status is 'offline'
        console.log 'offline', user
        _log.append "<li>#{user.nick} Offline</li>"

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

      _log.empty()
      add_log ch.records

      online_u = users.filter (u) -> u.status isnt 'offline'
      _users.text "#{online_u.length} / #{users.length}"
      $('#user-nick').text user.nick

      return
    # end of emit login
  return

login = Login.create el: '#login', user: user, logined: do_login
# console.log (new Login el: '#login', user: user, logined: do_login),
#   (Login.new el: '#login', user: user, logined: do_login)


window.channel = channel

channel.on 'connect', ->
  console.log 'connected'
  $ -> # dom ready, todo: wait for conn
    console.log 'domready'
    $('#conn-status').text 'online'

    _log = $ '#log'
    _users = $ '#users-list'
    _toolbar = $ '#toolbar'
    _entry = $ '#entry'

    _users.click ->
      alert channel.users.map((u) -> "#{u.nick} #{u.status}").join '\n'

    resize = ->
      setTimeout ->
        _e = _entry[0]
        _e.style.height = 'auto'
        _e.style.height = "#{Math.min Math.max(46, _e.scrollHeight), window.innerHeight / 2}px"

        _log.css 'padding-bottom', _toolbar.outerHeight() + 10 + 'px' # log resize
      , 0
    _entry.bind
      keydown: resize
      change: resize
      cut: resize
      past: resize
      drop: resize

    _entry.keydown (e) ->
      if e.keyCode is 13 and not (e.ctrlKey or e.metaKey or e.shiftKey or e.altKey)
        return false unless @value.trim()
        channel.message type: 'gfm', data: @value
        @value = ''
        false
    
    _entry.focus().change()

    channel.on 'system', (data) ->
      console.log 'got system message', data

    login.init() unless login.inited

channel.on 'disconnect', ->
  $('#conn-status').text 'offline'
