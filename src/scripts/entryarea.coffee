# imported by panel.coffee

class EntryArea extends View
  type: 'entry'
  mode: type: 'gfm' # default type for now
  constructor: (@cfg) ->
    super @cfg # with auto init
    @history = [''] # max length 100
    @history.cur = 0 # 0 for current value
    @preview_el = @parent.query '#preview'
    @preview_el.hidden = false # temp
    ### public ###
    Object.defineProperties @,
      value:
        get: -> @el?.value # do not trim
        set: (value) -> if @el? and value isnt @el.value
          @el.value = value # wont auto fire change event
          @fire 'change' # return
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
    if blob.size > 256 * 1024 # 256 K
      @channel.system 'The image is too large.' 
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
      # console.log 'length', data.length, @el.value.length, @el.maxLength
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
  # enter / up / down
  _trvl_history: (e, up = yes) =>
    return if @history.cur < 0 and @value # or (/\n/.test @value)
    # test cur pos
    i = @el.selectionStart
    v = @el.value
    unless up and i is 0 or not up and i is v.length - 1
      t = if up then v.slice 0, i else v.slice i
      return if /\n/.test t
    # end of test
    e.preventDefault()
    cur = @history.cur + if up then 1 else -1
    # console.log 'history', cur
    return false if cur < 0 or cur >= @history.length
    @history[0] = @value if @history.cur is 0
    @history.cur = cur
    @value = @history[cur]
    false
  _onkeydown: (e) ->
    # shift/alt + enter is new line ; enter (default) or ctrl/cmd + enter is send
    if e.keyCode is 13 and not (e.shiftKey or e.altKey)
      e.preventDefault()
      @_onchanged()
      return false unless @value.trim()
      @send()
      @value = '' # change fired
      # @_onchanged()
      return false
    else if e.keyCode is 38
      @_trvl_history e, yes
    else if e.keyCode is 40
      @_trvl_history e, no
    else if e.keyCode is 13 # new line
      @_onchanged()
    # else
    #   clearTimeout _delay if (_delay = @_onchanged._delay)
    #   @_onchanged._delay = @wait 300, @_onchanged
    return
  _onchanged: ->
    @_onchanged._delay = clearTimeout _delay if (_delay = @_onchanged._delay)
    if (_ov = @_onchanged._value) isnt (_nv = @value)
      @trigger 'changed', _ov, _nv, @
      # console.log 'changed', _ov, _nv
      @_onchanged._value = _nv
      @resize()
      @preview()
    return
  ### public ###
  init: ->
    super()
    # for keydown and changed
    _changed = @_onchanged.bind @
    @on 'keydown', (e) => @_onkeydown e
    @on 'input', (e) =>
      clearTimeout _delay if (_delay = @_onchanged._delay)
      @_onchanged._delay = @wait 300, @_onchanged
    @on 'cut', _changed
    @on 'past', _changed
    @on 'drop', _changed
    @on 'change', _changed
    # for placeholder
    @on 'focus', -> @placeholder = ''
    @on 'blur', -> @placeholder = '_'
    # for paste files
    if localStorage.paste is 'on' # tmp
      @on 'paste', (e) => @_onpaste e
    # for drop files
    # @on 'dragenter', (e) -> 
    # @on 'dragleave', (e) -> 
    @on 'dragover', (e) ->
      e.stopPropagation()
      e.preventDefault()
      # console.log 'dragover', e
      e.dataTransfer.dropEffect = 'copy' # Explicitly show this is a copy.
      false
    @on 'drop', (e) => @_ondrop e
    # auto save on exit
    @on 'unload', el: window, =>
      @history[0] = @value
      sessionStorage.history = JSON.stringify @history
      return
    @on 'resize', el: window, => @resize()
    # restore save # todo: use localstorage with sid
    if (_history = sessionStorage.history)
      try
        _history = JSON.parse _history
        # console.log _history
        _history = [''] unless (Array.isArray _history) and _history.length > 0
      catch error
        _history = ['']
      @history = _history
      @history.cur = 0
    if (@value = @history[0] or '')
      @wait -> @el.selectionStart = @el.value.length
    else
      _changed()
    @wait 300, @resize # ensure
    @
  # end of init
  ### public ###
  send: (txt = @value) ->
    msg = type: @mode.type, data: txt # todo: type
    channel.msg msg, (ok) => unless ok
      @channel.system "Send message timeout, this message may be lost:> #{msg.data}"
    # console.log @history[0].trim(), (@history.length < 2 or @history[0] isnt @history[1]), @history
    @history[0] = @value
    @history.cur = 0
    if @history.length < 2 or @history[0] isnt @history[1]
      @history.unshift ''
      @history.pop() while @history.length > 100 # max length 100
    @trigger 'sent', msg, @
    @
  # end of send
  resize: ->
    return @ unless @inited
    panel_changed = =>
      setTimeout =>
        @preview_el.style.height = @el.style.height # if preview
        @trigger 'resized', @
      , 0
    setTimeout =>
      old_height_px = @el.style.height
      @el.style.height = 'auto'
      if @el.scrollHeight is @el._old_height
        @el.style.height = old_height_px
      else
        @el._old_height = @el.scrollHeight
        @el.style.height = "#{Math.min @el.scrollHeight, window.innerHeight / 2}px"
        panel_changed() if old_height_px isnt @el.style.height
    , 0
    @
  # end of resize
  preview: -> # todo: sep renderer
    el = @preview_el
    unless @value.trim()
      el.innerHTML = ''
      el.style.height = 'auto'
    else
      # temp
      el.innerHTML = @parent.parent.msglog.render type: 'gfm', data: @value
      codes = [].slice.call el.querySelectorAll 'code'
      # console.log 'hi', codes, hljs
      codes.forEach (code) ->
        # hljs.tabReplace = '<span class="indent">\t</span>'
        hljs.highlightBlock code, null, (code.parentNode.tagName isnt 'PRE')
  # end of preview
# end of class

# additional events: sent:(msg)|resized|changed:(old,new,@)

View.reg EntryArea # reg
