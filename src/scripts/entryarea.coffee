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
  ### private ###
  _image_mime_regex: /image\/(?:png|jpeg|qjpeg|gif|bmp)/
  _ondrop: (e) ->
    # console.log e
    @_insertFiles [].slice.call e.dataTransfer.files
  _onpaste: (e) -> # paste images
    items = [].slice.call e.clipboardData.items
    files = items.filter((item) -> item.kind is 'file')
                 .map (item) -> item.getAsFile()
    return unless files.length
    # e.preventDefault() # alow file name pasted first
    @_insertFiles files
    return # alow file name pasted first
  _insertFiles: (files) ->
    return unless files
    # console.log 'files', files
    files = [files] unless Array.isArray files
    files.forEach (file) =>
      if @_image_mime_regex.test file.type
        @_insertImage file
      else
        return # todo: support txt/src code files
    false
  _insertImage: (blob) ->
    if blob.size > 512 * 1024 # 512 K
      @channel.system 'The image you pasted is too large.' 
      return
    return unless window.FileReader?
    reader = new FileReader
    reader.onload = do (blob) => (e) =>
      fname = if blob.name then " alt=\"#{blob.name}\" title=\"#{blob.name}\"" else ''
      dataurl = e.target.result
      @_insertText "<img src=\"#{dataurl}\"#{fname}/>" # todo: match mode
      return
    reader.readAsDataURL blob
    return false
  _insertText: (data = '') ->
    data = data.toString()
    if data.length + @el.value.length > @el.maxLength # maxlength
      console.log 'length', data.length, @el.value.length, @el.maxLength
      @channel.system 'The content exceed the max length.' 
      return
    s = @el.selectionStart
    e = @el.selectionEnd
    arr = @value.split ''
    # console.log 'insert', s, e, arr, data
    arr.splice s, s - e, data
    # console.log 'inserted', narr
    @value = arr.join ''
    @el.selectionStart = @el.selectionEnd = s + data.length
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
    # paste image
    if localStorage.pastimage is 'on' # tmp
      @on event: 'paste', handler: (e) => @_onpaste e
    # drop image
    # @on event: 'dragenter', handler: (e) -> 
    # @on event: 'dragleave', handler: (e) -> 
    @on event: 'dragover', handler: (e) ->
      e.stopPropagation()
      e.preventDefault()
      # console.log 'dragover', e
      e.dataTransfer.dropEffect = 'copy' # Explicitly show this is a copy.
      false
    @on event: 'drop', handler: (e) => @_ondrop e
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
  ### public ###
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
