###
MadTalk
client scripts
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

listeners = 
  aftersync: ->
    # todo: smarter filtering
    app.chat.msglog.append channel.records
    
    if channel.title
      document.title = "Channel #{channel.title} - MadTalk"
    else
      document.title = "A New Channel #{channel.id[1..]} - MadTalk"
    # doto: show title and creator in header
   
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
      # document.querySelector('#chat').hidden = false # todo: deal with this!
      
      app.chat.init().show()
      app.chat.panel.status.update().online on

      channel.listeners[k] = v for k, v of listeners

      return
    # channel.listeners.loginfailed = (err) ->
      # sessionStorage.user = null
      # alert 'login failed!\n' + err

    return


#$.extend channel.listeners, listeners
