# imported by views.coffee

import 'lib/showdown.js'

class MsgLog extends View
  type: 'msglog'
  constructor: (@cfg) ->
    super @cfg # with auto init

  ### static ###
  @create: (cfg) -> super @, cfg
  ### public ###
  init: ->
    super()
    @clear()
    #Object.defineProperties @, # el shotcuts
  # end of init
  clear: ->
    @el.innerHTML = ''
    @
  append: (msgs) ->
    msgs = [msgs] unless Array.isArray msgs
    return @ unless msgs.length
    fragment = document.createDocumentFragment()
    msgs.forEach (msg) =>
      return if msg.rendered # is msg.ts for modifies
      # todo: renderer
      li = document.createElement 'li'
      li.className = 'log ' + (msg.class or 'message') # default is message
      li.className += ' ' + msg.type if msg.type
      nick = if msg.user?.nick then @xss.str msg.user.nick else ''
      ts = new Date(msg.ts or new Date).toLocaleTimeString()
      li.innerHTML = "<div class=\"info\">
        <label class=\"nick\">#{nick}</label>
        <label class=\"ts\">#{ts}</label></div>
        <div class=\"data\">#{@render msg}</div>"
      fragment.appendChild li
      msg.rendered = msg.ts
      return
    @el.appendChild fragment
    @scroll no
    @
  # end of append
  renderers:
    text: (data) -> @xss.str(data).replace /\n/g, '<br/>'
    gfm: (sd = new Showdown.converter()).makeHtml.bind sd #! JS 1.8.5
  render: ({type, data}) ->
    #throw "unknown type to render #{type}" unless @renderers.hasOwnProperty type
    type = 'text' unless @renderers.hasOwnProperty type
    @renderers[type].call @, data
  # end of render

  scroll: (immediately = no) ->
    if immediately
      @el.lastChild?.scrollIntoView()
      #window.scrollTo 0, document.body.scrollHeight
    else
      setTimeout =>
        @scroll yes
      , 0
