###
MadTalk
client scripts
###

# "use strict"

# import client modules
import 'polyfills'
import 'channel'
import 'appview'

id = location.pathname
View.channel = channel = Channel.create {id, io}
window.app = app = AppView.create el: '#app'
app.channel = channel

channel.bind 'connected', -> #$ -> # dom ready
  
  channel.bind 'logined', ->
    msglog = app.chat.msglog

    channel.bind
      aftersync: ->
        # filtered while appending
        msglog.append channel.records
        
        if channel.title
          document.title = "Channel #{channel.title} - MadTalk"
        else
          document.title = "A New Channel #{channel.id} - MadTalk"
        # doto: show title and creator in header?
       
        app.chat.panel.status.update()
        return

      disconnected: ->
        msglog.append
          data: "You are offline now."
          class: 'offline'
        app.chat.panel.status.online off
        return

      aftermessage: (msg) ->
        msglog.append msg
        app.chat.notify msg
      aftersystem: (msg) ->
        msg.class = 'system'
        msglog.append msg

      afteruseronline: (user) ->
        msglog.append
          data: "User #{user.nick} is online now."
          class: 'offline'
          ts: user.ts
        app.chat.panel.status.update()
      afteruseroffline: (user) ->
        msglog.append
          data: "User #{user.nick} is offline now."
          class: 'offline'
          ts: user.ts
        app.chat.panel.status.update()
      # afterleave: ->
        #todo: leave and logout

    app.chat.init().show()
    app.chat.panel.status.update().online on
    return

  return

channel.connect()
app.init()
