###
* server side Channel class
* NOTICE
* avoid calling any method of instance manually, 
* just use Channel.create and it will handle everything
###

class Channel
  #! please use Channel.create instead of new Channel
  constructor: (@id, @io, @listeners) ->
    # auto bind listeners
    @bind @listeners if @listeners
    @init()

  ### static ###
  @ID_REGEX: /^\/?[\w\-]+$/ # '.' is not allowed
  @channels: []
  @create: ({id, io, listeners}) ->
    # default args
    id ?= @channels.length
    io ?= @io or throw 'no socket.io specified'
    if id isnt '?' # id='?' is a query
      # normalize id from '/xxxxx' to 'xxxxx'
      throw id "#{id} should be consist of 0-9,A-Z,a-z,_,-" unless @ID_REGEX.test id
      id = id[1..] if id[0] is '/'
      id = id.toLowerCase()
    # return exist channel
    return @channels.index[id] if @channels.index[id]?
    # create new channel
    channel = new @ id, io, listeners
    @channels.push @channels.index[id] = channel
    channel
  # end of static create
  @has: (id) ->
    id = id.id if id.id?
    id = id[1..] if id[0] is '/'
    @channels.index[id.toLowerCase()]?

  ### public ###
  init: -> # call by constuctor or manual after set id and io
    throw 'cannot init without id or io' unless @id and @io
    @ts = @last = new Date().getTime()
    @records = []
    @records.index = {} # indexed by ts
    @users = []
    @users.index = {} # indexed by nick and sid
    @clients = @io.of '/' + @id
    @clients.channel = @
    # Object.defineProperties @,
      # creator/admin
    # bind fns to client.io ! JS 1.8.5
    @on = @clients.on.bind @clients
    @emit = @clients.emit.bind @clients
    console.log 'channel created', @id
    # auto start listening
    @listen on if @auto_listen isnt off
    @inited = yes
    @trigger 'inited'
    @
  # end of init

  # # helper
  # wait: (t = 0, fn) ->
  #   if typeof t is 'function'
  #     [t, fn] = [fn or 0, t]
  #   t = if t < 0 then 0 else t >>> 0
  #   fn = fn.bind @
  #   setTimeout fn, t # return
  # # end of wait

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

  listen: -> # start listening, auto start when init
    console.log 'start listening channel', @id
    @on 'connection', (client) =>
      # start listen for login
      console.log 'a user conn, wait for login ...', client.id
      client.on 'login', (user, callback) =>
        user.sid = client.id
        console.log 'req login', user
        client.user = user
        try
          @validate client, (user) =>
            # bind event handlers
            @handle client
            # send login callback
            callback? user
            # push sync req
            @sync client
            # the 1st logined user is the creator
            unless @creator?
              user.creator = yes
              @creator = user
              console.log 'the creator', user.nick
              # send msg after login callback
              @system client, "Welcome #{user.nick}! 
You are the creator of this channel. 
Your first valid message will be the title of the channel!"
            else if user.creator? and user isnt @creator 
              delete user.creator
        catch err
          console.error err
          callback? err: err
        return
      # todo: set timeout for login
      # todo: manage clients
      # client.on 'relogin', (user, callback) =>
      #   user.sid = client.id
      #   console.log 'req re-login', user
      #   client.user = user
      #   try
      #     @validate client, (user) =>
      #       # bind event handlers
      #       @handle client
      #       # send login callback
      #       callback? user
      #       # push sync req
      #       @sync client
      #   catch err
      #     console.error err
      #     callback? err: err
      #   return
    @
  # end of listen

  _nick_regex: /^[^\x00-\x17\x22\x3c\x3e\x7f]{3,30}$/ # 3-30 no:[\x00-\x17\x22\x3c\x3e\x7f]
  validate: (client, callback) -> # check user add add to users
    throw 'invalid client' unless client?.user
    user = client.user
    throw 'invalid or empty nickname' unless user?.nick and @_nick_regex.test user.nick
    # for no user auth now, only allow single client per user
    throw 'nickname duplication' if @users.index[user.nick.toLowerCase()]?.online
    # todo: more exception
    # todo: user system, check

    # create or update user and reg to users
    if user.sid and (u = @users.index[user.sid])?
      # offline user
      delete @users.index[user.sid]
      if u.nick isnt user.nick
        # u.old_nick = u.nick # do not care, as a new user
        u.nick = user.nick # overwrite
      u.sid = client.id
      user = u # pick org user info
    else if user.nick and (u = @users.index[user.nick.toLowerCase()])?
      # not offline user, and nick dup
      throw 'nickname duplication' if u.online
      u.sid = client.id
      user = u # pick org user info
    else # new user
      user.sid = client.id
      @users.push user # add user to list
    @users.index[user.nick.toLowerCase()] = @users.index[user.sid] = user # build index
    client.user = user
    # return user
    callback? user
    @
  # end of validate

  handle: (client) -> # add listeners to a client, no callback yet
    user = client.user
    # set status
    user.status = 'online'
    user.online = yes
    console.log 'online', client.user.nick, client.user.online
    # broadcast one user connected
    client.broadcast.emit 'online', @_user_info user
    # end of brodcast
    @last = new Date().getTime() # last upt ts
    # listen and re-broadcast messages
    client.on 'message', (msg, callback) =>
      console.log 'a bad msg', msg, msg.user.nick unless msg?.data
      # the 1st msg from creator is the title if len > 3 after filered
      @_title client, msg.data if not @title and user is @creator
      # msg
      msg.user = # limit user info
        #id: user.id
        nick: user.nick
        # more?
      @msg msg
      callback? yes # may exists
      return
    # sync req
    client.on 'sync', (data, callback) =>
      last = data.last or data.ts or 0
      callback # must exists
        id: @id
        records: @records.filter (r) -> r.ts >= last
        users: @users.map (user) => @_user_info user
        last: @last # last update ts
        init: @ts # channel ts
        creator: @creator # todo: simplify data
        title: @title or null
        ts: new Date().getTime() # cur ts
      return
    # user offline
    client.on 'disconnect', =>
      console.log 'offline', client.user.nick, client.user.online
      return unless user.online
      user.status = 'offline'
      user.online = no
      client.broadcast.emit 'offline', @_user_info user
      return
    # user leave channel
    client.on 'leave', =>
      console.log 'user leave', user.nick, user.sid
      @users[user.sid] = null # not delete
      delete @users.index[user.nick.toLowerCase()]
      delete @users.index[user.sid]
      client.broadcast.emit 'leave', @_user_info user
      # todo: drop res
      return
    @
  # end of handle
  _user_info: (user) ->
    nick: user.nick
    #id: user.id
    #email?: user.email?
    online: user.online
    status: user.status
    ts: new Date().getTime()
  # end of extract user info
  _title: (client, title) -> # set title
    #console.log 'org msg for title', title
    title = title.replace(/[\x00-\x1f\n\r\t\s]+|(?:<[^><]{6,}>)/g, ' ').trim()
    #console.log 'title after trim', title
    if title.length > 3
      title = title[0...29] + '\u2026' if title.length > 30 # add ...
      console.log 'set title', title
      @title = title
      #@sync client, yes
      @sync yes # all, force
      @system client, "Your message '#{title}' has been set as title!"
    else
      @system client, "Your message '#{title}' is to too short or not suitable to set as title!"
    @
  # end of title

  msg: (msg) -> # broadcast message
    #todo: add a on message handler
    msg.type ?= ''
    #todo: add msg filter
    # gen a uniq ts
    ts = new Date().getTime()
    ts++ while @records.index[ts]?
    msg.ts = ts
    # add to records
    msg.id = @records.length
    @records.push @records.index[ts] = msg
    @last = msg.ts # last upt ts
    # broadcast to all user including sender
    console.log msg
    @emit 'message', msg
    @
  # end of msg

  system: (client = @clients, msg) ->
    console.log 'system', msg
    client.emit 'system',
      data: msg
      ts: new Date().getTime() # cur ts

  sync: (client = @clients, force) -> # ask spec user or all users to sync
    if client is yes and not force?
      force = yes
      client = @clients
    client.emit 'sync', # this is NOT channel sync data!
      force: Boolean force
      last: @last # last update ts
      ts: new Date().getTime() # cur ts
    @
  # end of sync

do -> # Channel helper
  C = Channel
  C.channels.index = {} # indexed by id
  # alias
  C::broadcastMessage = C::sendMessage = C::msg
  C::askSync = C::sync
  C::addUser = C::checkUser = C::validate
  C::handleUser = C::handle

exports.Channel = Channel if exports?
