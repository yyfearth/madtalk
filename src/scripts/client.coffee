###
MadTalk
client scripts
include jquery socket.io showdown
###

# madtalk client.coffee

# import libs
#import 'lib/jquery.js'
#import 'lib/socket.io.js'
# import modules
import 'polyfills'
import 'channel'
import 'views'

id = location.pathname
window.channel = View.channel = channel = Channel.create {id, io}

login = Login.create el: '#login'
msglog = MsgLog.create el: '#msglog'
panel = Panel.create { el: '#panel', msglog }

_users = null

_calc_users = -> ###############
  online_u = channel.users.filter (u) -> u.status isnt 'offline'
  _users.innerHTML = "#{online_u.length} / #{channel.users.length}"
  # _users.text "#{online_u.length} / #{channel.users.length}"

listeners = 
  logined: ->
    #msglog.show yes
    document.querySelector('#chat').hidden = false # todo: deal with this!

    document.querySelector('#conn-status').innerHTML = 'online'
    _nick = document.querySelector('#user-nick')
    _nick[if _nick.innerText? then 'innerText' else 'textContent'] = channel.user.nick
    # $('#conn-status').text 'online'
    # $('#user-nick').text channel.user.nick
    
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
   
    _calc_users() ##########
    return

  disconnected: ->
    msglog.append
      data: "You are offline now."
      class: 'offline'
    document.querySelector('#conn-status').text 'offline'
    # $('#conn-status').text 'offline'
    return
  aftermessage: (msg) ->
    msglog.append msg
  aftersystem: (msg) ->
    msg.class = 'system'
    msglog.append msg
  afteruseronline: (user) ->
    #alert 1
    msglog.append
      data: "User #{user.nick} is online now."
      class: 'offline'
      ts: user.ts
    _calc_users() ##########
  afteruseroffline: (user) ->
    msglog.append
      data: "User #{user.nick} is offline now."
      class: 'offline'
      ts: user.ts
    _calc_users() ##########
  # afterleave: ->
    #todo: leave and logout

  connected: -> #$ -> # dom ready
    # EP

    console.log 'domready'

    login.init()
    msglog.init()
    panel.init()

    # _users = $ '#users-list'
    _users = document.querySelector '#users-list'
    _users.onclick = ->
      alert channel.users.map((u) -> "#{u.nick} #{u.status}").join '\n'
    # _users.click ->
    #   alert channel.users.map((u) -> "#{u.nick} #{u.status}").join '\n'

channel.listeners[k] = v for k, v of listeners

#$.extend channel.listeners, listeners
