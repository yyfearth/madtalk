###
MadTalk
client scripts
include jquery socket.io showdown
###

# madtalk client.coffee

# import libs
import 'lib/jquery.js'
import 'lib/socket.io.js'
import 'lib/showdown.js'
# import modules
import 'channel'
import 'views'
import 'xss_safe'

id = location.pathname

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

window.channel = View.channel = channel = Channel.create {id, io, user}

login = null
msglog = null
pannel = null

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

auto_save = ->
  #todo: use localstorage with sid
  sessionStorage.auto_save = _entry?.val() or ''
  return

setInterval auto_save, 30000 # 30s

channel.listeners.logined = (user) ->
  msglog.show yes

  el = document.querySelector '#chat'
  el.hidden = false
  $('#user-nick').text user.nick
  
  window.onbeforeunload = ->
    #todo: use localstorage with sid
    sessionStorage.user = JSON.stringify channel.user
    auto_save()
    return

  save_text = sessionStorage.auto_save or ''
  _entry.val(save_text)[0].selectionStart = save_text.length
  return

channel.listeners.loginfailed = (err) ->
  alert 'login failed!\n' + err

channel.listeners.aftersync = (ch) ->
  _log.empty()
  add_log ch.records
  if ch.title
    ch.title = ch.title.replace /<.+?>|\n/g, ' '
    document.title = "Channel #{ch.title} - MadTalk"
  else
    document.title = "A New Channel #{channel.id[1..]} - MadTalk"
  # doto: show title and creator in header

  online_u = channel.users.filter (u) -> u.status isnt 'offline'
  _users.text "#{online_u.length} / #{channel.users.length}"
  return

channel.listeners.disconnected = (ch) ->
  $('#conn-status').text 'offline'
  return

channel.listeners.aftermessage = (msg) ->
  add_log msg

channel.listeners.afterleave = ->
  #todo: leave and logout

channel.listeners.connected = (ch) ->
  $ -> # dom ready
    console.log 'domready'

    login = Login.create el: '#login', auto: on
    msglog = MsgLog.create el: '#msglog', auto: on

    console.log login

    $('#conn-status').text 'online'

    _log = $ '#msglog'
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
        channel.msg type: 'gfm', data: @value
        _entry.history.unshift @value
        _entry.history.cur = -1
        @value = ''
        false
      else if e.keyCode is 38
        get_history yes unless /\n/.test @value
      else if e.keyCode is 40
        get_history no unless /\n/.test @value
    
    _entry.change()

    return
