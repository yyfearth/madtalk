class StatusBar extends View
  type: 'status'
  constructor: (@cfg) ->
    super @cfg # with auto init
  ### static ###
  @create: (cfg) -> super @, cfg
  ### public ###

# end of class

class EntryArea extends View
  type: 'entry'
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
      return
    # change
    old_value = null
    fire_change = (e) => if @value isnt old_value
      old_value = @value
      # todo: reduce times
      # sessionStorage.auto_save = @value or '' # auto save
      # console.log 'changed'
      @fire event: 'change' # return
    # end of fire_change
    @on event: 'keydown', handler: fire_change
    @on event: 'cut', handler: fire_change
    @on event: 'past', handler: fire_change
    @on event: 'drop', handler: fire_change
    @on event: 'change', handler: => @resize()
    # auto save on exit
    @on el: window, event: 'unload', handler: =>
        sessionStorage.auto_save = @value or ''
        return
    # restore save # todo: use localstorage with sid
    @value = auto_save = sessionStorage.auto_save or ''
    if auto_save
      setTimeout =>
        @el.selectionStart = @el.value.length
      , 0
    else
      fire_change()
    @
  # end of init
  send: ->
    txt = @value
    channel.msg type: 'gfm', data: txt # todo: type
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
