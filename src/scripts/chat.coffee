# imported by appview.coffee
# markdown and highlight for msglog and panel
import 'lib/pagedown.mod.js'
import 'lib/highlight.pack.js'
import 'notifier'
# sub views
import 'msglog'
import 'panel'

class Chat extends View
  type: 'chat'
  constructor: (@cfg) ->
    super @cfg # with auto init
    @msglog = MsgLog.create el: '#msglog', parent: @
    @panel = Panel.create el: '#panel', parent: @
    throw 'Notifier is not ready' unless Notifier?.audios?
    @notifier = new Notifier
  ### static ###
  @create: (cfg) -> super @, cfg
  ### public ###
  init: ->
    super()
    console.log 'chat init'
    @notifier.init() # todo: init after login, move to chat view
    @notifier.onfocus = => @activate yes
    @on 'focus', el: window, => @activate on
    @on 'blur' , el: window, => @activate off
    # init views
    @msglog.init()
    @panel.init()
    @panel.bind 'resize', =>
      @msglog.bottom = @panel.height + 1 # log resize
      return
    @activate on # default on
    @
  activate: (active = on) ->
    @active = active # globle lock
    @notifier.active = not @active
    if active
      window.focus()
      @panel.entry.el.focus()
    @
  notify: (msg) ->
    @notifier?.notify msg
    @

View.reg Chat # reg
