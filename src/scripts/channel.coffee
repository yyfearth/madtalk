###
* client side Channel class
###
import 'lib/socket.io+websocket.js'

class Channel
  #! please use Channel.create instead of new Channel
  constructor: (@id, @io, @user) ->
    # auto bind listeners
    @bind @listeners

    @trigger 'created', @

    @init()

  ### static ###
  @create: ({id, io, user}) ->
    throw 'cannot init without id or io' unless id? and io
    # normalize id from '/xxxxx' to 'xxxxx'
    id = id[1..] if id[0] is '/'
    id = id.toLowerCase()
    channel = new @ id, io, (user or null)
  # end of static create

  ### internal methods ###
  init: -> # call by constuctor or manual after set id and io
    throw 'cannot init without id or io' unless @id and @io
    @ts = new Date().getTime()
    @last = @init = 0
    @records = [] # no overwrite while sync
    @records.index = {} # index by ts
    @users = []  # overwrite while sync
    @logined = no
    @_load_user() unless @user?.nick
    @trigger 'inited', @
    # auto connect
    @connect on if @auto_connect
    @
  # end of init
  _load_user: -> 
    try
      user = sessionStorage.user or localStorage["channel-#{@id}-user"]
      if user
        user = JSON.parse user
        throw 'bad user session data' unless user?.nick
      else
        user = null
    catch e
      console.error 'bad user session data', e
      user = null
    @user = user
    return
  _save_user: -> if @logined and @user?.nick
    sessionStorage.user = JSON.stringify @user
    localStorage["channel-#{@id}-user"] = JSON.stringify
      nick: @user.nick
      # _ts: new Date().getTime()
    return
  _clear_user: ->
    delete sessionStorage.user
    delete localStorage["channel-#{@id}-user"]
    return

  # # helper
  wait: (t = 0, fn) ->
    if typeof t is 'function'
      [t, fn] = [fn or 0, t]
    t = if t < 0 then 0 else t >>> 0
    fn = fn.bind @
    setTimeout fn, t # return
  # end of wait

  # custom events
  bind: (event, fct) ->
    return @ unless event
    unless fct? and typeof event is 'string'
      for e, f of event
        @bind e, f if event.hasOwnProperty e
      return @
    unless typeof event is 'string' and typeof fct is 'function'
      throw 'invalid params for bind custom event bind(str, fn)'
    # console.log 'bind', event, fct
    ((@_events ?= {})[event] ?= []).push fct
    @
  unbind: (event, fct) ->
    return @ unless event
    unless fct? and typeof event is 'string'
      for e, f of event
        @unbind e, f if event.hasOwnProperty e
      return @
    unless typeof event is 'string' and typeof fct is 'function'
      throw 'invalid params for unbind custom event unbind(str, fn)'
    (evts = @_events?[event])?.splice? evts.indexOf(fct), 1
    @
  unbindAll: -> @_events = {}
  trigger: (event, args...) ->
    return false if false is @_events?[event]?.every? (fct) => false isnt fct.apply @, args
    @
  # end of custom events
 
  event_regex: ///^(:? leave
    | system | message | sync | leave
    | (:?user)?(?:online|offline|leave)
  )$ ///i

  _evt: (event) -> # validate event
    throw 'invalid event' unless event
    throw "not such event #{event}" unless @event_regex.test event
    "#{event}".toLowerCase()

  _bind: (event, _fireevent) =>
    event = @_evt event
    _fireevent = if _fireevent then @_evt _fireevent else event
    @socket.on event, (args...) => @_fire _fireevent, args...
    @

  _fire: (event, args...) =>
    event = @_evt event
    return @ if false is @trigger "before#{event}", args... # call before event listeners
    return @ if false is @["on#{event}"]? args... # on event
    @trigger "after#{event}", args... # call before event listeners
    @

  ### methods ###
  base: '/' # 'http://madtalk.yyfearth.com:8008/'
  connect: (isretry) -> # start connect, auto start when init
    url = @base + @id
    console.log 'connect', url
    if @socket
      @socket.removeAllListeners() # clean all listeners
      @socket.disconnect()
    sio = @socket = @io.connect url # connect to server
    unless @connected then _timeout = @wait 3000, -> # 3s
      _timeout = null
      if isretry
        location.reload() if confirm 'Connection Timeout!\n Click OK to retry.'
      else
        @retry()
    # listen connect
    sio.on 'connect', =>
      _timeout = clearTimeout _timeout if _timeout
      @connected = yes
      @trigger 'connected', @ # call connected
      @socket.on 'disconnect', =>
        @trigger 'disconnected', @ # bind disconnect
        @connected = no
        return
      @_bind 'system' # bind system msg
    sio.on 'connect_failed', =>
      _timeout = clearTimeout _timeout if _timeout
      @connected = no
      @trigger 'connectfailed', type, attempts
      alert 'connect failed'
    sio.on 'connecting', (t) ->
      console.log 'connecting', t
    sio.on 'reconnect', (type, attempts) =>
      # @connected = yes
      # todo: do not need to re-login for reconnection
      location.reload() if confirm 'Reconneced Reload Required!\n Click OK to retry.'
      # return if false is @trigger 'reconnecting', type, attempts
      # sio.removeAllListeners()
      # @connect()
      @retry =>
        @connect yes
        # @relogin()
      @trigger 'reconnected', type, attempts
    # bind fns to client.io ! JS 1.8.5
    console.log 'wait for connect msg'
    @
  # end of connect

  retry: (callback) ->
    console.log 'retry, send ch query'
    url = location.pathname + '!?'
    xhr = new XMLHttpRequest
    throw 'need ajax support' unless xhr
    xhr.onreadystatechange = => if xhr.readyState is 4
      console.log 'query callback', xhr.status
      if xhr.status is 304
        if callback
          callback? no
        else
          @connect yes
      else if xhr.status is 201
        if confirm 'Updated!\n Click OK to reload.'
          location.reload()
        else
          if callback
            callback? yes
          else
            @connect yes
      else if xhr.status is 404
        console.error 'server is down, retry in 5s ...'
        @wait 5000, -> @connect yes
      else
        console.error "invalid status #{xhr.status}"
    xhr.open 'GET', url, true
    xhr.send null
    return

  login: (callback) -> # do login, called by outside
    return @ if @logined
    throw 'no user info' unless @user?.nick
    console.log 'do login', @user
    @socket.emit 'login', @user, (upduser) =>
      console.log 'login callback', upduser
      unless upduser?.nick
        #throw upduser.err
        # @user?.nick = null
        err = upduser?.err or 'unknown error'
        @trigger 'loginfailed', err # call logined
        callback? err
        @_clear_user()
        return
      @user.sid = upduser.sid
      # @user.id = upduser.id
      @user.nick = upduser.nick
      @user.status = upduser.status
      # copy all user props?
      @logined = yes
      return if false is @trigger 'logined', @user # call logined
      @listen()
      callback? null # no err
      @_save_user()
      return
    @
  # end of login

  relogin: (callback) -> # do re-login, called by outside
    throw 'no user info' unless @user?.nick
    console.log 'do re-login', @user
    @socket.emit 'relogin', @user, (upduser) =>
      console.log 'login callback', upduser
      unless upduser?.nick
        #throw upduser.err
        # @user?.nick = null
        err = upduser?.err or 'unknown error'
        @trigger 'loginfailed', err # call logined
        callback? err
        @_clear_user()
        return
      @user.sid = upduser.sid
      # @user.id = upduser.id
      @user.nick = upduser.nick
      @user.status = upduser.status
      # copy all user props?
      @logined = yes
      return if false is @trigger 'relogined', @user # call logined
      callback? null # no err
      @_save_user()
      return
    @
  # end of relogin

  logout: -> # tmp
    return @ unless @logined
    # todo: send logout to server
    @logined = no
    @_clear_user()
    location.reload()
    @

  record: (rec) -> # add record
    #if (r = @records.index[rec.ts])? # exists
      #@records[r.idx] = @records.index[r.ts] = rec
      # no overwrite
    #else # new
    unless @records.index.hasOwnProperty rec.ts
      rec.idx = @records.length
      @records.push @records.index[rec.ts] = rec
    @
  # end of record

  dump: -> localStorage["channel_dump_#{@id}"] = JSON.stringify @records

  timeout: 10000 # 10s
  ### send message
  @param msg {object} messsage data {data: 'xxx', type: 'text|gfm|md|...'}
  @param callback {function} server boardcase successful, function (bool ok)
  ###
  msg: (msg, callback) ->
    throw 'not logined' unless @logined
    throw 'invalid msg data' unless msg?.data
    msg.type ?= ''
    _callback = null
    #msg.user = @user server will discard this
    if typeof callback is 'function'
      _t = @wait @timeout, -> callback false # timeout
      _callback = (ok) ->
        clearTimeout _t
        callback ok is yes

    @socket.emit 'message', msg, _callback
    # todo: add event here
    @
  # end of msg

  sync: (force = off) -> # req sync
    throw 'not logined' unless @logined
    ts = new Date().getTime()
    return @ unless force or ts - @last > 10000 # 10s
    @socket.emit 'sync',
      last: @last
    , (ch) =>
      return @ if false is @trigger 'beforesync', ch # call event listeners
      @info = ch
      #@id = ch.id
      @users = ch.users # included me
      @users.index = {} # nick only
      ch.users.forEach (u) => @users.index[u.nick.toLowerCase()] = u
      if ch.records?.length
        ch.records.forEach (r) => @record r
      @init = ch.init # channel init time
      @last = ch.last # last update
      @title = ch.title?.replace /<.+?>|\n/g, ' '
      @creator = ch.creator
      @trigger 'aftersync', ch # call after event listeners
      @
    @
  # end of sync

  system: (msg) -> # local system msg
    @_fire 'system',
      data: msg
      local: yes
      ts: new Date().getTime()
  # end of system

  leave: -> @_fire 'leave'
  
  listen: ->
    @socket.on 'sync', (ch) => @sync ch.force is yes # req sync

    @_bind 'message'

    # user online offline leave
    @onuseronline = @onuseroffline = @onuserjoin
    @_bind 'online', 'useronline'
    @_bind 'offline', 'useroffline'
    @_bind 'leave', 'userleave'

    @
  # end of listen

  ### events ###
  onleave: -> @socket.emit 'leave' if @logined
  onmessage: (msg) -> @record msg if @logined
  onuserjoin: (user) -> # when user online or offline
    return unless @logined
    status = if user.online then 'online' else 'offline'
    if (u = @users.index[user.nick.toLowerCase()])? # add to list if not exists
      return false if u.online is user.online
      u.online = user.online
      u.status = user.status
      # todo: customize status and change status event
    else
      @users.push @users.index[user.nick.toLowerCase()] = user
      console.log 'push users', user, @users
    return
  onuserleave: (user) -> # untested
    return unless @logined
    if user.nick is @user.nick and user.kicked # kicked
      @leave() # ask to leave
    else if (u = @users.index[(nick = user.nick.toLowerCase())])?
      return @ if false is @trigger 'beforeuserleave', u # call before event listeners
      @users.splice (@users.indexOf u), 1 # delete
      delete @users.index[nick]
    return

  # todo: reconnect / reconnect_failed event

  # event listeners
  listeners: # listenerss _fired before event return false to cancel
    # created: (ch) ->
    inited: (ch) ->
      console.log 'channel init', ch.id
      return
    connected: (ch) ->
      console.log 'connected'
      return
    disconnected: (ch) ->
      console.log 'disconnected'
      return
    reconnected: (type, attempts) ->
      console.log 'reconnected', type, attempts
    logined: (user) ->
      console.log 'logined', user
      return
    loginfailed: (err) ->
      console.error 'login failed', err
      return
    beforesystem: (msg) ->
      console.log 'got system message', msg
      true
    beforemessage: (msg) ->
      console.log 'got message', msg
      true
    # aftermessage: (msg) ->
    beforesync: (ch) ->
      console.log 'got sync data', ch
      true
    # aftersync: (ch) ->
    beforeuseronline: (user) ->
      console.log 'user online', user
    # afteruseronline: (user) ->
    beforeuseroffline: (user) ->
      console.log 'user offline', user
    # afteruseroffline: (user) ->
    # beforeuserleave: (user) ->
    # afteruserleave: (user) ->
    # beforeleave: ->
    # afterleave: ->
  # end of listeners

do -> # helper
  # aliases
  C = Channel.prototype
  C.message = C.sendMessage = C.msg
