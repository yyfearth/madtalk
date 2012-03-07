###
MadTalk
client scripts
###

# import client modules
import 'polyfills'
import 'channel'
import 'appview'

id = location.pathname
View.channel = channel = Channel.create {id, io}
window.app = app = AppView.create el: '#app'
app.channel = channel

listeners = 
  aftersync: ->
    # filtered while appending
    app.chat.msglog.append channel.records
    
    if channel.title
      document.title = "Channel #{channel.title} - MadTalk"
    else
      document.title = "A New Channel #{channel.id[1..]} - MadTalk"
    # doto: show title and creator in header?
   
    app.chat.panel.status.update()
    return

  disconnected: ->
    app.chat.msglog.append
      data: "You are offline now."
      class: 'offline'
    app.chat.panel.status.online off
    return

  aftermessage: (msg) ->
    app.chat.msglog.append msg
    app.chat.notify msg
  aftersystem: (msg) ->
    msg.class = 'system'
    app.chat.msglog.append msg

  afteruseronline: (user) ->
    app.chat.msglog.append
      data: "User #{user.nick} is online now."
      class: 'offline'
      ts: user.ts
    app.chat.panel.status.update()
  afteruseroffline: (user) ->
    app.chat.msglog.append
      data: "User #{user.nick} is offline now."
      class: 'offline'
      ts: user.ts
    app.chat.panel.status.update()
  # afterleave: ->
    #todo: leave and logout

channel.listeners.connected = -> #$ -> # dom ready
    # EP
    app.init()

    channel.listeners.logined = ->
      app.chat.init().show()
      app.chat.panel.status.update().online on
      # listen to msg after login
      channel.listeners[k] = v for k, v of listeners
      return

    # channel.listeners.loginfailed = (err) ->
      # alerts already handled by login

    return
