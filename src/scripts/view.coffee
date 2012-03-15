# imported by app view

import 'xss'

class View # view controller base class
  # type: 'view' the name of view, subclass must have this
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
          _el = @query _el, _parent if typeof _el is 'string'
      height: get: -> @el.clientHeight
      width: get: -> @el.clientWidth
      inited: get: -> _el? and @init isnt _init # has el and @init isnt org
      hidden:
        get: -> _el.hidden
        set: (value) ->
          return if false is @trigger "before#{if value then 'show' else 'hide'}", @
          _el.hidden = Boolean value
          _el.style.display = if value then 'none' else 'block'
          @trigger "after#{if value then 'show' else 'hide'}", @
          return
    # console.log 'constructor view'

    # auto bind listeners
    if (_lsnrs = @cfg.listeners)?
      @_events = {}
      for event, listener of _lsnrs
        @_events[event] = [listener] if _lsnrs.hasOwnProperty event

    @trigger 'created', @
    # auto init
    @init() if @cfg.auto
  ### static ###
  ###
  @param type {string} view class type e.g. 'login', 'msglog'
  @param cfg {object} config must have el and channel
  ###
  @create: (type, cfg = {}) ->
    throw 'need view class' unless type
    cfg = el: cfg if typeof cfg is 'string'
    #type = type::type if type::type # if type is a view
    type = View._views[type.toLowerCase()] if typeof type is 'string'
    unless typeof type is 'function' and View._views.hasOwnProperty type::type
      throw "unknown view class #{type}"
    view = type
    type = view::type
    cfg.el ?= '#' + type # default el
    cfg.channel ?= View.channel or throw 'cannot create a view without channel'
    cfg.channel.views ?= {}
    console.log 'create', type
    cfg.channel.views[type] = new view cfg # return
  # end of create
  @_views: {} # reg subclasses
  @reg: (sub) ->
    throw 'sub class sould be a view class' unless (typeof sub is 'function') and sub::type
    @_views[sub::type] = sub
    @
  ### public ###
  xss: xss_safe # util
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
    @trigger 'inited', @
    @
  query: (selector, parent) ->
    (parent or @el or document).querySelector selector
  queryAll: (selector, parent) ->
    (parent or @el or document).querySelectorAll selector
  # end of init

  # show hide shortcuts
  show: (show = yes) ->
    @hidden = not show
    @
  hide: (hide = yes) ->
    @hidden = hide
    @

  # dom events
  _els: ({els, el}) ->
    if el and els
      throw 'only set one of el or els'
    else if el
      el = @query el if typeof el is 'string'
      els = [el]
    else if els
      els = [].slice.call @queryAll els if typeof els is 'string'
      els = [els] unless Array.isArray els
    else
      els = [@el]
    els
  # end of get els
  on: (event, {els, el, handler, bind}) -> # els or el
    throw 'need event name' unless event
    # for (event, ..., handler)
    if not handler? and (l = arguments.length) > 1 and typeof (h = arguments[l - 1]) is 'function'
      handler = h
      el = els = bind = null if l is 2
    throw 'need handler function' if typeof handler isnt 'function'
    # get els
    els = @_els {el, els}
    console.log 'on', event, els, bind, handler
    # bind
    els.forEach (el) ->
      if bind isnt off # on
        el.addEventListener event, handler, false
      else # of
        el.removeEventListener event, handler, false
      return
    @
  # end of on
  un: (event, opt) ->
    opt = handler: opt if typeof opt is 'function'
    opt.bind = off
    @on event, opt
  # end of off
  fire: (event, {els, el, data, e} = {}) ->
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
  # end of dom events

  # helper
  wait: (t = 0, fn) ->
    if typeof t is 'function'
      [t, fn] = [fn or 0, t]
    t = if t < 0 then 0 else t >>> 0
    fn = fn.bind @
    setTimeout fn, t # return
  # end of wait

  # custom events
  bind: (event, fct) ->
    ((@_events ?= {})[event] ?= []).push fct
    @
  unbind: (event, fct) ->
    (evts = @_events?[event])?.splice? evts.indexOf(fct), 1
    @
  trigger: (event, args...) ->
    return false if false is @_events?[event]?.every? (fct) => fct.apply @, args
    @
  # end of custom events

  # events: inited|(before|after)(show|hide)
