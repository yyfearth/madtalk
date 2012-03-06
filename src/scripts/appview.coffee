# imported by views.coffee

class AppView extends View
  type: 'app'
  constructor: (@cfg) ->
    super @cfg # with auto init
    @login = Login.create el: '#login'
    @msglog = MsgLog.create el: '#msglog'
    @panel = Panel.create el: '#panel', msglog: @msglog
    throw 'Notifier is not ready' unless Notifier?.audios?
    @notifier = new Notifier
  ### static ###
  @create: (cfg) -> super @, cfg
  ### public ###
  init: ->
    super()
    @notifier.init()
    @notifier.onfocus = => @activate yes
    @on event: 'focus', el: window, handler: => @activate on
    @on event: 'blur' , el: window, handler: => @activate off
    # init views
    @login.init()
    @msglog.init()
    @panel.init()
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