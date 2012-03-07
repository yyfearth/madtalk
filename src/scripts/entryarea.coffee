# imported by panel.coffee

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
        # todo: delay _resize
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
      , 300
    @
  # end of init
  send: ->
    txt = @value
    channel.msg type: @mode.type, data: txt # todo: type
    @history.unshift txt if @history[0] isnt txt
    @history.cur = -1
    @value = ''
    @resize()
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
      @el.style.height = 'auto'
      panel_resize()
    @
# end of class

View.reg EntryArea # reg
