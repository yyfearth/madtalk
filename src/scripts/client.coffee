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
    app.chat.init().show()
    # app.chat.panel.status.online on # force
    return

channel.connect()

# do ->
#   url = location.pathname
#   xhr = new XMLHttpRequest
#   throw 'need ajax support' unless xhr
#   xhr.onreadystatechange = -> if xhr.readyState is 4
#     if xhr.status is 304
#       channel.connect()
#     else if xhr.status is 200
#       channel.connect() # reload?
#     else
#       console.error "invalid status #{xhr.status}"
#   xhr.open 'GET', url, true
#   xhr.send null
#   return
