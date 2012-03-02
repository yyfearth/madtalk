###
MadTalk
client scripts
include jquery socket.io showdown
###

# madtalk client.coffee

# import libs
import 'lib/jquery.js'
#import 'lib/socket.io.js'
# import modules
import 'polyfills'
import 'channel'
import 'views'

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

id = location.pathname
window.channel = View.channel = channel = Channel.create {id, io, user}

login = Login.create el: '#login'
msglog = MsgLog.create el: '#msglog'
panel = Panel.create { el: '#panel', msglog }

_users = null
_entry = null

init = ->
  console.log 'domready'

  login.init()
  msglog.init()
  panel.init()

  _users = $ '#users-list'
  # _toolbar = $ '#panel'
  # _entry = $ '#entry'
  # _entry.history = []
  # _entry.history.cur = -1 # for prev is 0

  _users.click ->
    alert channel.users.map((u) -> "#{u.nick} #{u.status}").join '\n'

  ###############
  # do resize = ->
  #   setTimeout ->
  #     _e = _entry[0]
  #     _e.style.height = 'auto'
  #     _e.style.height = "#{Math.min Math.max(46, _e.scrollHeight), window.innerHeight / 2}px"

  #     msglog.el.style.bottom = _toolbar.outerHeight() + 'px' # log resize
  #   , 0
  # _entry.bind
  #   keydown: resize
  #   change: resize
  #   cut: resize
  #   past: resize
  #   drop: resize

  # get_history = (up = yes) ->
  #   cur = _entry.history.cur + if up then 1 else -1
  #   #console.log 'history', cur
  #   return false if cur < 0 or cur >= _entry.history.length
  #   _entry.history.cur = cur
  #   _entry.val _entry.history[cur]
  #   false

  # _entry.keydown (e) ->
  #   if e.keyCode is 13 and not (e.ctrlKey or e.metaKey or e.shiftKey or e.altKey)
  #     return false unless @value.trim()
  #     channel.msg type: 'gfm', data: @value
  #     _entry.history.unshift @value
  #     _entry.history.cur = -1
  #     @value = ''
  #     false
  #   else if e.keyCode is 38
  #     get_history yes unless /\n/.test @value
  #   else if e.keyCode is 40
  #     get_history no unless /\n/.test @value
  
  # _entry.change()

  # return

# auto_save = ->
#   #todo: use localstorage with sid
#   sessionStorage.auto_save = _entry?.val() or ''
#   return

# setInterval auto_save, 30000 # 30s

listeners = 
  logined: ->
    #msglog.show yes
    document.querySelector('#chat').hidden = false # todo: deal with this!

    $('#conn-status').text 'online'
    $('#user-nick').text channel.user.nick
    
    window.onbeforeunload = ->
      #todo: use localstorage with sid
      sessionStorage.user = if channel.user?.nick then JSON.stringify channel.user else null
      auto_save()
      return

    # save_text = sessionStorage.auto_save or ''
    # _entry.val(save_text)[0].selectionStart = save_text.length
    return

  loginfailed: (err) ->
    sessionStorage.user = null
    alert 'login failed!\n' + err

  aftersync: ->
    # todo: smarter filtering
    msglog.append channel.records
    
    if channel.title
      document.title = "Channel #{channel.title} - MadTalk"
    else
      document.title = "A New Channel #{channel.id[1..]} - MadTalk"
    # doto: show title and creator in header
   
    ###############
    online_u = channel.users.filter (u) -> u.status isnt 'offline'
    _users.text "#{online_u.length} / #{channel.users.length}"
    return

  disconnected: ->
    msglog.append
      data: "You are offline now."
      class: 'offline'
    $('#conn-status').text 'offline'
    return
  aftermessage: (msg) ->
    msglog.append msg
  aftersystem: (msg) ->
    msg.class = 'system'
    msglog.append msg
  afteruseronline: (user) ->
    #alert 1
    msglog.append
      data: "User #{user.nick} is online now."
      class: 'offline'
      ts: user.ts
  afteruseroffline: (user) ->
    msglog.append
      data: "User #{user.nick} is offline now."
      class: 'offline'
      ts: user.ts
  afterleave: ->
    #todo: leave and logout
  connected: ->
    $ -> init() # dom ready

$.extend channel.listeners, listeners
