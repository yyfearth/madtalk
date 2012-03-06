
import 'statusbar'
import 'entryarea'

class Panel extends View
  type: 'panel'
  constructor: (@cfg = {}) ->
    throw 'need msglog view' unless @cfg.msglog?._is_view
    super @cfg # with auto init
    ### private ###
    _msglog = @cfg.msglog #ref
    _get_view = (type, el) =>
      el ?= '#' + type
      return el if el._is_view
      View.create type, { el, parent: @ } # return , channel: @channel 
    # end of get view
    _status = _get_view 'status', @cfg.status
    _entry  = _get_view 'entry', @cfg.entry
    ### public ###
    Object.defineProperties @,
      msglog: value: _msglog
      status: value: _status
      entry: value: _entry

  ### static ###
  @create: (cfg) -> super @, cfg
  ### internal ###
  _resize: -> # call by entry, after entry has been resized
    @msglog.el.style.bottom = @height + 'px' # log resize
  ### public ###
  init: ->
    @status.init() unless @status.inited
    @entry.init() unless @entry.inited
    super()

    @
  # end of init
