###
* client side Channel class
###

class Channel
  #! please use Channel.create instead of new Channel
  constructor: (@id, @io, @user) ->
    @init()

  ### static ###
  @create: ({id, io, user}) ->
    throw 'cannot init without id or io' unless id? and io
    # normalize id to '/xxxxx'
    id = '/' + id unless /^\//.test id
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
    console.log 'channel init', @id
    # auto connect
    @connect on if @auto_connect isnt off
    @
  # end of init

  event_regex: ///^(:? leave
    | system | message | sync
    | (:?user)?(?:online|offline|leave)
  )$ ///i

  _evt: (event) -> # validate event
    throw 'invalid event' unless event
    throw "not such event #{event}" unless @event_regex.test event
    "#{event}".toLowerCase()

  bind: (event, fireevent) =>
    event = @_evt event
    fireevent = if fireevent then @_evt fireevent else event
    @on event, (args...) => @fire fireevent, args...
    @

  fire: (event, args...) =>
    event = @_evt event
    return @ if false is @listeners["before#{event}"]? args... # call before event listeners
    return @ if false is @["on#{event}"]? args... # on event
    @listeners["after#{event}"]? args... # call before event listeners
    @

  ### methods ###

  connect: -> # start connect, auto start when init
    console.log 'connect', @id
    @socket = io.connect @id # connect to server
    # bind fns to client.io ! JS 1.8.5
    @on = @socket.on.bind @socket
    @emit = @socket.emit.bind @socket
    console.log 'wait for connect msg'
    # listen connect
    @on 'connect', =>
      return if false is @listeners.connected? @ # call connected
      @on 'disconnect', => @listeners.disconnected? @ # bind disconnect
      @bind 'system'
    @
  # end of connect

  login: (callback) -> # do login, called by outside
    return @ if @logined
    throw 'no user info' unless @user?.nick
    console.log 'do_login', @user
    @emit 'login', @user, (upduser) =>
      if upduser.err
        #throw upduser.err
        @listeners.loginfailed? upduser.err # call logined
        callback? upduser.err
      @user.sid = upduser.sid
      @user.id = upduser.id
      @user.status = upduser.status
      # copy all user props?
      return if false is @listeners.logined? @user # call logined
      @logined = yes
      @listen()
      callback? null # no err
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

  ### send message
  @param msg {object} messsage data {data: 'xxx', type: 'text|gfm|md|...'}
  @param callback {function} server boardcase successful, function (bool ok)
  ###
  msg: (msg, callback) ->
    throw 'not logined' unless @logined
    throw 'invalid msg data' unless msg?.data
    msg.type ?= 'text'
    #msg.user = @user server will discard this
    if typeof callback is 'function'
      callback = (ok) -> callback ok
    else
      callback = null
    @emit 'message', msg, callback
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
      return @ if false is @listeners.beforesync? ch # call event listeners
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
      @listeners.aftersync? ch # call after event listeners
      @
    @
  # end of sync

  leave: -> @fire 'leave'
  
  listen: ->
    @on 'sync', (ch) => @sync ch.force is yes # req sync

    @bind 'message'

    # user online offline leave
    @onuseronline = @onuseroffline = @onuserjoin
    @bind 'online', 'useronline'
    @bind 'offline', 'useroffline'
    @bind 'leave', 'userleave'

    @
  # end of listen

  ### events ###
  onleave: -> @emit 'leave' if @logined
  onmessage: (msg) -> @record msg if @logined
  onuserjoin: (user) -> # status must be online or offline
    return unless @logined
    status = if user.online then 'online' else 'offline'
    return @ if false is @listeners["beforeuser#{status}"]? user # call before event listeners
    @users.push user unless @users.index[user.nick]?
    @users.index[user.nick].status = user.status
    @listeners["afteruser#{status}"]? user # call before event listeners
    return
  onuserleave: (user) ->
    return unless @logined
    if user.sid is @user.sid and user.kicked # kicked
      @leave() # ask to leave
    else if (u = @users.index[user.nick])?
      return @ if false is @listeners.beforeuserleave? u # call before event listeners
      @users[u.idx] = null # not delete
      delete @users.index[u.nick]
      @listeners.afteruserleave? u # call before event listeners
    return

  # event listeners
  listeners: # listenerss fired before event return false to cancel
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
      console.error upduser
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
    # beforeuseronline: (user) ->
    # afteruseronline: (user) ->
    # beforeuseroffline: (user) ->
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
