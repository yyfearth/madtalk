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
      return el if el._is_view
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
  ### internal ###
  _resize: -> # call by entry, after entry has been resized
    @parent?._resize?() # pass to chat
    return
  ### public ###
  init: ->
    @status.init() unless @status.inited
    @entry.init() unless @entry.inited
    super()

    @
  # end of init

View.reg Panel # reg
