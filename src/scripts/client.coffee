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
View.channel = channel = Channel.create {id, io}
window.app = app = AppView.create el: '#app'
app.channel = channel

# login = Login.create el: '#login'
# msglog = MsgLog.create el: '#msglog'
# panel = Panel.create { el: '#panel', msglog }

listeners = 
  logined: ->
    document.querySelector('#chat').hidden = false # todo: deal with this!
    app.panel.status.update().online on
    return

  # loginfailed: (err) ->
    # sessionStorage.user = null
    # alert 'login failed!\n' + err

  aftersync: ->
    # todo: smarter filtering
    app.msglog.append channel.records
    
    if channel.title
      document.title = "Channel #{channel.title} - MadTalk"
    else
      document.title = "A New Channel #{channel.id[1..]} - MadTalk"
    # doto: show title and creator in header
   
    app.panel.status.update()
    return

  disconnected: ->
    app.msglog.append
      data: "You are offline now."
      class: 'offline'
    app.panel.status.online off
    return
  aftermessage: (msg) ->
    app.msglog.append msg
    app.notify msg
  aftersystem: (msg) ->
    msg.class = 'system'
    app.msglog.append msg
  afteruseronline: (user) ->
    app.msglog.append
      data: "User #{user.nick} is online now."
      class: 'offline'
      ts: user.ts
    app.panel.status.update()
  afteruseroffline: (user) ->
    app.msglog.append
      data: "User #{user.nick} is offline now."
      class: 'offline'
      ts: user.ts
    app.panel.status.update()
  # afterleave: ->
    #todo: leave and logout

  connected: -> #$ -> # dom ready
    # EP
    app.init()
    # login.init()
    # msglog.init()
    # panel.init()

    return

channel.listeners[k] = v for k, v of listeners

#$.extend channel.listeners, listeners
