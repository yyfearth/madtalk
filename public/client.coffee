# madtalk client.coffee
channel = io.connect '/0'

try
  user = sessionStorage.user
  user = JSON.parse user if user
  throw 'bad user session data' unless user?.nick
catch e
  console.error 'bad user session data', e
  user = nick: prompt 'nickname:'

channel.on 'connect', ->
  console.log 'connected'

  channel.emit 'login', user, (newuser) -> # updated user profile

    if newuser.err
      console.error newuser
    else
      console.log 'logined', newuser
      user.uid = newuser.uid

      channel.on 'online', (user) ->
        console.log 'online', user

      channel.on 'offline', (user) ->
        console.log 'offline', user

      channel.on 'message', (data) ->
        console.log 'got message', data

      channel.message = (data) ->
        channel.emit 'message', data, (ok) ->
          if ok
            console.log 'message sent', data
          else
            console.error data

window.channel = channel

window.onbeforeunload = ->
  sessionStorage.user = JSON.stringify user
  'sure to exit?'

$ -> # dom ready
