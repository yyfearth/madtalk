@title = 'Loading...'
@canonical = 'http://madtalk.yyfearth.com:8008/'

#h1 @title

div '#popups', -> div '#mask', ->
  partial 'login'

partial 'chat'

if @dev
  # script src: '/socket.io/socket.io+websocket.js'
  script defer: on, @js # client.js
else
  script src: "client.js?#{@ts}", async: on
