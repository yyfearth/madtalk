@title = 'Loading...'
@canonical = 'http://madtalk.yyfearth.com:8008/'

#h1 @title

text @partial 'login'

text @partial 'chat'

if @dev
  # script src: '/socket.io/socket.io+websocket.js'
  script defer: on, @js # client.js
else
  script src: 'client.js', defer: on
