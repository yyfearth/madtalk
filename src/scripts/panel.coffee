# imported by chat view

# sub views
import 'statusbar'
import 'entryarea'

class Panel extends View
  type: 'panel'
  constructor: (@cfg = {}) ->
    super @cfg # with auto init
    ### private ###
    _get_view = (type, el) =>
      el ?= '#' + type
      return el if el instanceof View
      View.create type, { el, parent: @ } # return , channel: @channel 
    # end of get view
    _status = _get_view 'status', @cfg.status
    _entry  = _get_view 'entry', @cfg.entry
    ### public ###
    Object.defineProperties @,
      status: value: _status
      entry: value: _entry

  ### static ###
  @create: (cfg) -> super @, cfg
  ### public ###
  init: ->
    @status.init() unless @status.inited
    @entry.init() unless @entry.inited
    super()
    @entry.bind 'resized', => @trigger 'resized'
    @addcls 'preview' # temp
    @
  # end of init

View.reg Panel # reg
