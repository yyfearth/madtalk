class StatusBar extends View
  type: 'status'
  constructor: (@cfg) ->
    super @cfg # with auto init
  ### static ###
  @create: (cfg) -> super @, cfg
  ### public ###
  init: ->
    super()
    @nick = @query '#user-nick'
    @list = @query '#users-list'
    @conn = @query '#conn-status'
    @
  _text: (el, txt) ->
    el[if el.innerText? then 'innerText' else 'textContent'] = txt
  update: ->
    return @ unless @init
    # user nick
    @_text @nick, @channel.user.nick
    # users list
    online_u = 0 #@channel.users.filter (u) -> u.status isnt 'offline'
    @list.title = @channel.users.map((u) ->
      online_u++ if u.status isnt 'offline'
      "* #{u.nick} #{u.status}").join '\n'
    @_text @list, @list.counter = "#{online_u} / #{channel.users.length}"
    @list.onclick ?= =>
      @channel.system "*Users in this channel #{@list.counter}*\n\n#{@list.title}"
      false
    @
  online: (online = on) ->
    @_text @conn, if online then 'online' else 'offline'
    @
# end of class

class EntryArea extends View
  type: 'entry'
  mode: type: 'gfm' # default type for now
  constructor: (@cfg) ->
    super @cfg # with auto init
    @history = [] # todo: save history with cur value together
    @history.cur = -1 # for prev is 0
    ### public ###
    Object.defineProperties @,
      value:
        get: -> @el?.value # do not trim
        set: (value) -> if @el? and value isnt @el.value
          @el.value = value # wont auto fire change event
          @fire event: 'change' # return
  ### static ###
  @create: (cfg) -> super @, cfg
  ### public ###
  init: ->
    super()
    _resize = @resize.bind @ # JS 1.8.5
    # enter / up / down
    _trvl_history = (e, up = yes) =>
      return if @history.cur < 0 and @value or /\n/.test @value
      e.preventDefault()
      cur = @history.cur + if up then 1 else -1
      #console.log 'history', cur
      return false if cur < 0 or cur >= @history.length
      @history.cur = cur
      @value = @history[cur]
      false
    @on event: 'keydown', handler: (e) =>
      if e.keyCode is 13 and not (e.ctrlKey or e.metaKey or e.shiftKey or e.altKey)
        e.preventDefault()
        return false unless @value.trim()
        @send()
        return false
      else if e.keyCode is 38
        _trvl_history e, yes
      else if e.keyCode is 40
        _trvl_history e, no
      else if e.keyCode is 13 # new line
        _resize()
      else
        
      return
    # end of fire_change
    # @on event: 'keydown', handler: _resize
    @on event: 'cut', handler: _resize
    @on event: 'past', handler: _resize
    @on event: 'drop', handler: _resize
    @on event: 'change', handler: _resize
    # placeholder
    @on event: 'focus', handler: -> @placeholder = ''
    @on event: 'blur', handler: -> @placeholder = '_'
    # auto save on exit
    @on el: window, event: 'unload', handler: =>
        sessionStorage.auto_save = @value or ''
        return
    @on el: window, event: 'resize', handler: => @resize()
    # restore save # todo: use localstorage with sid
    @value = auto_save = sessionStorage.auto_save or ''
    if auto_save
      setTimeout =>
        @el.selectionStart = @el.value.length
      , 0
    else # try
      _resize()
      setTimeout ->
        _resize()
      , 100
    @
  # end of init
  send: ->
    txt = @value
    channel.msg type: @mode.type, data: txt # todo: type
    @history.unshift txt if @history[0] isnt txt
    @history.cur = -1
    @value = ''
    @
  # end of send
  resize: ->
    return @ unless @inited
    panel_resize = =>
      setTimeout =>
        @parent?._resize?()
      , 0
    if @value?.trim()
      setTimeout =>
        @el.style.height = 'auto'
        @el.style.height = "#{Math.min @el.scrollHeight, window.innerHeight / 2}px"
        panel_resize()
      , 0
    else
      panel_resize()
    @
# end of class

class Panel extends View
  type: 'panel'
  constructor: (@cfg = {}) ->
    throw 'need msglog view' unless @cfg.msglog?._is_view
    super @cfg # with auto init
    ### private ###
    _msglog = @cfg.msglog #ref
    _get_view = (type, el) =>
      el ?= '#' + type
      return el if el._is_view
      View.create type, { el, parent: @ } # return , channel: @channel 
    # end of get view
    _status = _get_view 'status', @cfg.status
    _entry  = _get_view 'entry', @cfg.entry
    ### public ###
    Object.defineProperties @,
      msglog: value: _msglog
      status: value: _status
      entry: value: _entry

  ### static ###
  @create: (cfg) -> super @, cfg
  ### internal ###
  _resize: -> # call by entry, after entry has been resized
    @msglog.el.style.bottom = @height + 'px' # log resize
  ### public ###
  init: ->
    @status.init() unless @status.inited
    @entry.init() unless @entry.inited
    super()

    @
  # end of init
