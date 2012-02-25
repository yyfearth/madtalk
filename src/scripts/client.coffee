# madtalk client.coffee

#import 'lib/showdown.js'
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
_entry = null

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

      channel.el = document.querySelector '#chat'
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
        #todo: use localstorage with sid
        sessionStorage.user = JSON.stringify user
        auto_save()
        return

      _log.empty()
      add_log ch.records

      online_u = users.filter (u) -> u.status isnt 'offline'
      _users.text "#{online_u.length} / #{users.length}"
      $('#user-nick').text user.nick

      save_text = sessionStorage.auto_save or ''
      _entry.val(save_text)[0].selectionStart = save_text.length

      return
    # end of emit login
  return

login = Login.create el: '#login', user: user, logined: do_login
# console.log (new Login el: '#login', user: user, logined: do_login),
#   (Login.new el: '#login', user: user, logined: do_login)

auto_save = ->
  #todo: use localstorage with sid
  sessionStorage.auto_save = _entry?.val() or ''
  return

window.channel = channel

channel.on 'connect', ->
  console.log 'connected'
  $ -> # dom ready, todo: wait for conn
    console.log 'domready'
    $('#conn-status').text 'online'

    _log = $ '#log'
    _users = $ '#users-list'
    _toolbar = $ '#panel'
    _entry = $ '#entry'
    _entry.history = []
    _entry.history.cur = -1 # for prev is 0

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

    get_history = (up = yes) ->
      cur = _entry.history.cur + if up then 1 else -1
      #console.log 'history', cur
      return false if cur < 0 or cur >= _entry.history.length
      _entry.history.cur = cur
      _entry.val _entry.history[cur]
      false

    _entry.keydown (e) ->
      if e.keyCode is 13 and not (e.ctrlKey or e.metaKey or e.shiftKey or e.altKey)
        return false unless @value.trim()
        channel.message type: 'gfm', data: @value
        _entry.history.unshift @value
        _entry.history.cur = -1
        @value = ''
        false
      else if e.keyCode is 38
        get_history yes unless /\n/.test @value
      else if e.keyCode is 40
        get_history no unless /\n/.test @value
    
    ent = _entry.change()

    channel.on 'system', (data) ->
      console.log 'got system message', data

    login.init() unless login.inited

channel.on 'disconnect', ->
  $('#conn-status').text 'offline'
