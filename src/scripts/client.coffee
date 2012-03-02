###
MadTalk
client scripts
include jquery socket.io showdown
###

# madtalk client.coffee

# import modules
import 'polyfills'
import 'channel'
import 'views'

id = location.pathname
window.channel = View.channel = channel = Channel.create {id, io}

login = Login.create el: '#login'
msglog = MsgLog.create el: '#msglog'
panel = Panel.create { el: '#panel', msglog }

listeners = 
  logined: ->
    document.querySelector('#chat').hidden = false # todo: deal with this!
    panel.status.update().online on
    return

  # loginfailed: (err) ->
    # sessionStorage.user = null
    # alert 'login failed!\n' + err

  aftersync: ->
    # todo: smarter filtering
    msglog.append channel.records
    
    if channel.title
      document.title = "Channel #{channel.title} - MadTalk"
    else
      document.title = "A New Channel #{channel.id[1..]} - MadTalk"
    # doto: show title and creator in header
   
    panel.status.update()
    return

  disconnected: ->
    msglog.append
      data: "You are offline now."
      class: 'offline'
    panel.status.online off
    return
  aftermessage: (msg) ->
    msglog.append msg
  aftersystem: (msg) ->
    msg.class = 'system'
    msglog.append msg
  afteruseronline: (user) ->
    msglog.append
      data: "User #{user.nick} is online now."
      class: 'offline'
      ts: user.ts
    panel.status.update()
  afteruseroffline: (user) ->
    msglog.append
      data: "User #{user.nick} is offline now."
      class: 'offline'
      ts: user.ts
    panel.status.update()
  # afterleave: ->
    #todo: leave and logout

  connected: -> #$ -> # dom ready
    # EP
    login.init()
    msglog.init()
    panel.init()

    return

channel.listeners[k] = v for k, v of listeners

#$.extend channel.listeners, listeners
