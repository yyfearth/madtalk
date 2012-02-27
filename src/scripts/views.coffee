
class View # view controller base class
  constructor: (@cfg) ->
    # PLEASE USE View.create 'view', cfg instead of new
    throw 'bad cfg' unless @cfg? and @cfg.channel and @cfg.el
    @channel = @cfg.channel
    ### private ###
    _el = null
    _init = @init # org init
    ### public ###
    Object.defineProperties @,
      el:
        get: -> _el
        set: (value) ->
          _el = value
          _el = document.querySelector _el if typeof _el is 'string'
      inited: get: -> _el? and @init isnt _init # has el and @init isnt org
      hidden:
        get: -> _el.hidden
        set: (value) -> _el.hidden = Boolean value
    console.log 'constructor view'

    # auto init
    @init() if @cfg.auto
  ### static ###
  # @view: 'view' the name of view, subclass must have this
  # @create: moved to the end of file
  ### public ###
  init: ->
    unless @inited # to ensure run only once
      console.log 'init', @type # only once
      _init = @init # org init
      _init.inited = true
      @init = (force = no) ->
        throw 'inited' if @inited and not force
        console.log 'force re-init', @type
        _init.call @
    # end of unless inited
    @el = @cfg.el if @cfg.el
    @hidden = @cfg.hidden if @cfg.hidden?
  # end of init
  show: (show = yes) ->
    @hidden = not show
    @
  hide: (hide = yes) ->
    @hidden = hide
    @

### import views ###
import 'login'
import 'msglog'

### factory ###
_views =
  login: Login
  msglog: MsgLog

###
@param type {string} view class type e.g. 'login', 'msglog'
@param cfg {object} config must have el and channel
###
View.create = (type, cfg = {}) ->
  throw 'need view class' unless type
  #type = type::type if type::type # if type is a view
  type = _views[type.toLowerCase()] if typeof type is 'string'
  unless typeof type is 'function' and _views.hasOwnProperty type::type
    throw "unknown view class #{type}"
  view = type
  type = view::type
  cfg.el ?= '#' + type # default el
  cfg.channel ?= View.channel or throw 'cannot create a view without channel'
  cfg.channel.views ?= {}
  console.log 'create', type
  cfg.channel.views[type] = new view cfg # return
# end of create
