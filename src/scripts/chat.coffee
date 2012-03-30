# imported by appview.coffee
# markdown and highlight for msglog and panel
import 'lib/pagedown.mod.js'
import 'lib/highlight.pack.js'
# sub views
import 'msglog'
import 'panel'

class Chat extends View
  type: 'chat'
  constructor: (@cfg) ->
    super @cfg # with auto init
    @msglog = MsgLog.create el: '#msglog', parent: @
    @panel = Panel.create el: '#panel', parent: @
    _active = null
    ### public ###
    Object.defineProperties @,
      active:
        get: -> _active
        set: (value) ->
          @_activate (_active = value) if _active isnt value
          return
  ### static ###
  @create: (cfg) -> super @, cfg
  ### public ###
  init: ->
    super()
    console.log 'chat init'
    @on 'focus', el: window, => @active = on
    @on 'blur' , el: window, => @active = off
    # init views
    @msglog.init()
    @panel.init()
    @panel.bind 'resized', =>
      # console.log 'resized - reflow'
      @msglog.bottom = @panel.height + 1 # log resize
      return
    @active = on # default on
    @
  _activate: (active = on) -> # call by msglog
    @msglog.active = active # wont circle
    console.log 'chat active', active
    if active
      window.focus()
      @panel.entry.el.focus() # useless?
    @

View.reg Chat # reg
