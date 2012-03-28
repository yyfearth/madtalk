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
  _save_user: -> if @user?.nick
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

  _bind: (event, fireevent) =>
    event = @_evt event
    fireevent = if fireevent then @_evt fireevent else event
    @on event, (args...) => @fire fireevent, args...
    @

  fire: (event, args...) =>
    event = @_evt event
    return @ if false is @trigger "before#{event}", args... # call before event listeners
    return @ if false is @["on#{event}"]? args... # on event
    @trigger "after#{event}", args... # call before event listeners
    @

  ### methods ###
  base: '/' # 'http://madtalk.yyfearth.com:8008/'
  connect: -> # start connect, auto start when init
    url = @base + @id
    console.log 'connect', url
    @socket = io.connect url # connect to server
    # bind fns to client.io ! JS 1.8.5
    @on = @socket.on.bind @socket
    @emit = @socket.emit.bind @socket
    console.log 'wait for connect msg'
    # listen connect
    @on 'connect', =>
      return if false is @trigger 'connected', @ # call connected
      @on 'disconnect', => @trigger 'disconnected', @ # bind disconnect
      @_bind 'system'
    @
  # end of connect

  login: (callback) -> # do login, called by outside
    return @ if @logined
    throw 'no user info' unless @user?.nick
    console.log 'do login', @user
    @emit 'login', @user, (upduser) =>
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
      @user.id = upduser.id
      @user.status = upduser.status
      # copy all user props?
      return if false is @trigger 'logined', @user # call logined
      @logined = yes
      @listen()
      callback? null # no err
      @_save_user()
      return
    @
  # end of login

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

    @emit 'message', msg, _callback
    # todo: add event here
    @
  # end of msg

  sync: (force = off) -> # req sync
    throw 'not logined' unless @logined
    ts = new Date().getTime()
    return @ unless force or ts - @last > 10000 # 10s
    @emit 'sync',
      last: @last
    , (ch) =>
      return @ if false is @trigger 'beforesync', ch # call event listeners
      @info = ch
      #@id = ch.id
      @users = ch.users # included me
      @users.index = {}
      ch.users.forEach (u) => @users.index[u.nick] = u
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
    @fire 'system',
      data: msg
      local: yes
      ts: new Date().getTime()
  # end of system

  leave: -> @fire 'leave'
  
  listen: ->
    @on 'sync', (ch) => @sync ch.force is yes # req sync

    @_bind 'message'

    # user online offline leave
    @onuseronline = @onuseroffline = @onuserjoin
    @_bind 'online', 'useronline'
    @_bind 'offline', 'useroffline'
    @_bind 'leave', 'userleave'

    @
  # end of listen

  ### events ###
  onleave: -> @emit 'leave' if @logined
  onmessage: (msg) -> @record msg if @logined
  onuserjoin: (user) -> # status must be online or offline
    return unless @logined
    status = if user.online then 'online' else 'offline'
    return @ if false is @trigger "beforeuser#{status}", user # call before event listeners
    @users.push @users.index[user.nick] = user unless @users.index[user.nick]?
    @users.index[user.nick].status = user.status
    return
  onuserleave: (user) ->
    return unless @logined
    if user.sid is @user.sid and user.kicked # kicked
      @leave() # ask to leave
    else if (u = @users.index[user.nick])?
      return @ if false is @trigger 'beforeuserleave', u # call before event listeners
      @users[u.idx] = null # not delete
      delete @users.index[u.nick]
      @trigger 'afteruserleave', u # call before event listeners
    return

  # todo: reconnect / reconnect_failed event

  # event listeners
  listeners: # listenerss fired before event return false to cancel
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
  C = Channel
  C::message = C::sendMessage = C::msg
