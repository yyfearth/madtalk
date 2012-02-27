# imported by views.coffee

class MsgLog extends View
  type: 'msglog'
  constructor: (@cfg) ->
    super @cfg # with auto init

  ### static ###
  @create: (cfg) -> super @, cfg
  ### public ###
  init: ->
    super()

    #Object.defineProperties @, # el shotcuts
      