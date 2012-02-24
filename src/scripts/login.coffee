
class Login
  constructor: (@cfg = el: '#login') ->
    @user = if @cfg.user?.nick then @cfg.user else null
    @logined = @cfg.logined if typeof @cfg.logined is 'function'

    ### private ###
    _el = null

    ### public ###
    Object.defineProperties @,
      el:
        get: -> _el
        set: (value) ->
          _el = value
          _el = document.querySelector _el if typeof _el is 'string'
      inited: get: -> _el?
      hidden: get: -> _el.hidden

  ### static ###
  @create: (cfg) -> new @ cfg
  ### public ###
  init: ->
    return if @inited
    console.log 'init'
    @el = @cfg.el if @cfg.el
    @show not @user?.nick
    @form = @el.querySelector 'form'
    @form.onsubmit = (e) =>
      e.preventDefault()
      @user = nick: @form.nick.value
      @show off
      @logined? @user
      false
    @logined? @user if @user?.nick
    @

  show: (show = yes) ->
    console.log 'show', show, @el
    @el.hidden = not show
    @

  hide: ->
    @show off


