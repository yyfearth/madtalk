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

channel.bind
  connected: ->
    app.init()
    return
  logined: ->
    # channel.bind
      # afterleave: ->
        #todo: leave and logout
    app.chat.init().show() unless app.chat.inited
    # app.chat.panel.status.online on # force
    return

channel.connect()
