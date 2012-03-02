
import 'xss_safe'

class View # view controller base class
  constructor: (@cfg) ->
    # PLEASE USE View.create 'view', cfg instead of new
    throw 'bad cfg' unless @cfg? and @cfg.channel and @cfg.el
    @channel = @cfg.channel
    @parent = @cfg.parent if @cfg.parent?._is_view
    ### private ###
    _el = null
    _init = @init # org init
    ### public ###
    Object.defineProperties @,
      _is_view: value: yes
      el:
        get: -> _el
        set: (value) ->
          _el = value
          _parent = @parent?.el or document
          _el = _parent.querySelector _el if typeof _el is 'string'
      height: get: -> @el.clientHeight
      width: get: -> @el.clientWidth
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
  xss: xss_safe # util
  listeners: {}
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
    @
  # end of init
  show: (show = yes) ->
    @hidden = not show
    @
  hide: (hide = yes) ->
    @hidden = hide
    @
  # event
  _els: ({els, el}) ->
    if el and els
      throw 'only set one of el or els'
    else if el
      el = @el.querySelector el if typeof el is 'string'
      els = [el]
    else if els
      els = [].slice.call @el.querySelectors els if typeof els is 'string'
      els = [els] unless Array.isArray els
    else
      els = [@el]
    els
  # end of get els
  on: ({event, els, el, handler, bind}) -> # els or el
    throw 'need event name' unless event
    throw 'need handler function' if typeof handler isnt 'function'
    # get els
    els = @_els {el, els}
    # bind
    els.forEach (el) ->
      if bind isnt off # on
        el.addEventListener event, handler, false
      else # of
        el.removeEventListener event, handler, false
      return
    @
  # end of on
  off: (opt) ->
    opt.bind = off
    @on opt
  # end of off
  fire: ({event, els, el, data, e}) -> # untested yet! event is the name
    # get els
    els = @_els {el, els}
    # prepare e
    unless e
      e = document.createEvent 'HTMLEvents'
      if data? and typeof data is 'object'
        e[k] = v for k, v of data
      # fire
      e.initEvent event, true, true # event type,bubbling,cancelable
    els.forEach (el) -> el.dispatchEvent e # return
    @
  # end of fire
### import views ###
import 'login'
import 'msglog'
import 'panel'

### chat ###
# need import msglog, panel



### factory ###
_views =
  login: Login
  msglog: MsgLog
  panel: Panel
  status: StatusBar
  entry: EntryArea

###
@param type {string} view class type e.g. 'login', 'msglog'
@param cfg {object} config must have el and channel
###
View.create = (type, cfg = {}) ->
  throw 'need view class' unless type
  cfg = el: cfg if typeof cfg is 'string'
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
