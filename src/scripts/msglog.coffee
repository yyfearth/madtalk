# imported by views.coffee
import 'notifier'

class MsgLog extends View
  type: 'msglog'
  constructor: (@cfg) ->
    super @cfg # with auto init
    throw 'Notifier is not ready' unless Notifier?.audios?
    @notifier = new Notifier
    @notifier.onfocus = => @active = yes # override
    _active = null
    ### public ###
    Object.defineProperties @,
      bottom:
        get: -> parseFloat @el.style.bottom
        set: (value) ->
          value += 'px' if (typeof value is 'number') or /$[\d\.]+$/.test value
          @el.style.bottom = value
          return
      scrollbottom: get: -> @el.scrollTop + @el.clientHeight - 20
      active:
        get: -> _active
        set: (value) ->
          @_activate (_active = value) if _active isnt value
          return
  ### static ###
  @create: (cfg) -> super @, cfg
  ### public ###
  init: ->
    super()
    @listen()
    @clear()
    hljs.initHighlighting()
    @notifier.init()
    @on 'scroll', => @_scrolled()
    #Object.defineProperties @, # el shotcuts
  # end of init
  listen: ->
    _append = @append.bind @
    _title = @_title.bind @
    _notify = (msg) => @notifier.notify? msg
    @channel.bind
      aftersync: ->
        # filtered while appending
        _append channel.records
        _title channel.title
        return

      disconnected: ->
        _append
          data: "You are offline now."
          class: 'offline'
        return

      aftermessage: (msg) ->
        _append msg
        _notify msg
      aftersystem: (msg) ->
        msg.class = 'system'
        _append msg

      afteruseronline: (user) ->
        _append
          data: "User #{user.nick} is online now."
          class: 'offline'
          ts: user.ts
      afteruseroffline: (user) ->
        _append
          data: "User #{user.nick} is offline now."
          class: 'offline'
          ts: user.ts
    @
  clear: ->
    @el.innerHTML = ''
    @
  append: (msgs) ->
    msgs = [msgs] unless Array.isArray msgs
    return @ unless msgs.length
    return @ if false is @trigger 'beforeappend', msgs, @
    fragment = document.createDocumentFragment()
    msgs.forEach (msg) => unless msg.rendered # is msg.ts for modifies
      fragment.appendChild @_renderitem msg
      msg.rendered = msg.ts
      return
    @el.appendChild fragment
    codes = [].slice.call @el.querySelectorAll 'code'
    # console.log 'hi', codes, hljs
    codes.forEach (code) ->
      # hljs.tabReplace = '<span class="indent">\t</span>'
      hljs.highlightBlock code, null, (code.parentNode.tagName isnt 'PRE')
    @trigger 'afterappend', msgs, @
    @wait 300, @_updateread # force
    @scroll() # auto scroll
    @
  # end of append
  _renderitem: (msg) ->
    # todo: renderer
    li = document.createElement 'li'
    li.className = 'log'
    @addcls li, msg.class or 'message' # default is message
    @addcls li, msg.type if msg.type
    @addcls li, 'unread' unless msg.local
    nick = if msg.user?.nick then @xss.str msg.user.nick else ''
    ts = new Date(msg.ts or new Date).getShortTimeString no
    li.innerHTML = "<div class=\"info\">
      <label class=\"nick\">#{nick}</label>
      <label class=\"ts\">#{ts}</label></div>
      <div class=\"data\">#{@render msg}</div>"
    li.setAttribute 'data-ts', msg.ts
    li
  # end of render list
  renderers:
    default: # http://webreflection.blogspot.com/2012/02/js1k-markdown.html
      `function _1kmd(f){/*!(C) WebReflection*/for(var b="</code></pre>",c="blockquote>",e="(?:\\r\\n|\\r|\\n|$)",d="(.+?)"+e,a=[],h=["&(?!#?[a-z0-9]+;)","&amp;","<","&lt;",">","&gt;","^(?:\\t| {4})"+d,function(i,j){return a.push(j+"\n")&&"\0"},"^"+d+"=+"+e,"<h1>$1</h1>\n","^"+d+"-+"+e,"<h2>$1</h2>\n","^(#+)\\s*"+d,function(i,l,k,j){return"<h"+(j=l.length)+">"+k.replace(/#+$/,"")+"</h"+j+">\n"},"(?:\\* \\* |- - |\\*\\*|--)[-*][-* ]*"+e,"<hr/>\n","  +"+e,"<br/>","^ *(\\* |\\+ |- |\\d+. )"+d,function(i,l,k,j){return"<"+(j=/^\d/.test(l)?"ol>":"ul>")+"<li>"+_1kmd(k)+"</li></"+j},"</(ul|ol)>\\s*<\\1>","","([_*]{1,2})([^\\2]+?)(\\1)",function(i,l,k,j){return"<"+(j=l.length==2?"strong>":"em>")+k+"</"+j},"\\[(.+?)\\]\\((.+?) (\"|')(.+?)(\\3)\\)",'<a href="$2" title="$4">$1</a>',"^&gt; "+d,function(i,j){return"<"+c+_1kmd(j)+"</"+c},"</"+c+"\\s*<"+c,"","(\x60{1,2})([^\\r\\n]+?)\\1","<code>$2</code>","\\0",function(i){return"<pre><code>"+a.shift()+b},b+"\\s*<pre><code>",""],g=0;g<h.length;){f=f.replace(RegExp(h[g++],"gm"),h[g++])}return f}`
    text: (data) -> "<pre>#{data}</pre>" #@xss.str(data).replace /\n/g, '<br/>'
    code: (data) -> "<pre><code>#{data}</code></pre>"
    md: Markdown.md
    gfm: Markdown.gfm
  render: ({type, data}) ->
    #throw "unknown type to render #{type}" unless @renderers.hasOwnProperty type
    type = 'default' unless @renderers.hasOwnProperty type
    @renderers[type].call @, data
  # end of render

  # override with a simpler implitation
  # only accept one el and one cls
  cls: (act = 'add', el = @el, cls) ->
    if not cls and typeof el is 'string'
      cls = el
      el = @el
    if el.classList
      return false if false is el.classList[act] cls
    else
      switch act
        when 'add'
          el.className += cls unless (new RegExp "\\b#{cls}\\b", 'i').test el.className
        when 'remove'
          el.className = el.className.replace (new RegExp "\\b#{cls}\\b", 'ig'), ''
        when 'contains'
          return (new RegExp "\\b#{cls}\\b", 'i').test el.className
    @

  _activate: (active = on) ->
    console.log 'msglog active', active
    @_updateread() if active
    @notifier.active = not @active
    @parent.active = active # wont circle
    @
  _updateread: -> # updated unread status
    return unless @active
    els = @queryAll 'li.log.unread'
    return unless els.length
    # console.log 'for unread', els.length, els
    isreadall = els.every (el) =>
      read = el.offsetTop < @scrollbottom
      if read
        ts = el.getAttribute 'data-ts'
        @rmcls el, 'unread'
        @trigger 'read', ts >>> 0, el, @
        @_last_read = el
        # console.log 'read', el, read
      # else console.log 'unread', el.offsetTop, @scrollbottom, el
      read
    return
  _title: ->
    ch = @channel
    if ch.title
      document.title = "Channel #{ch.title} - MadTalk"
    else
      document.title = "A New Channel #{ch.id} - MadTalk"
    @notifier.title = document.title
    # doto: show title and creator in header?
  _scrolled: -> # defered scrolled
    return if @_scrolled._defer
    @_scrolled._defer = @wait 1000, -> # 1s
      @_scrolled._defer = null
      # console.log 'scrolled', @el.scrollTop
      @trigger 'scrolled', @el.scrollTop, @
      @_updateread()
    return
  scroll: ({defered, force} = {}) -> # default: {yes, no}
    return @ unless (last = @el.lastChild)? # for no exception
    _scroll = =>
      # do not scroll unless last read msg above client height
      # console.log 'scroll req', force, @_last_read.offsetTop, @scrollbottom
      return @ unless force or ((@_last_read or @el).offsetTop - @scrollbottom < @el.clientHeight)
      # console.log 'do scroll'
      # return @ if false is @trigger 'beforescroll', @el.scrollTop, @
      if last.scrollIntoViewIfNeeded?
        last.scrollIntoViewIfNeeded()
      if last.scrollIntoView?
        last.scrollIntoView()
      else
        @el.scrollTop = last.offsetTop
      @_scrolled()
    # end of _scroll
    if defered ? on
      @wait _scroll
    else
      _scroll()
    @
  exports: -> # (type = 'html')
    ul = document.createElement 'ul'
    ul.id = 'msglog'
    @channel.records.forEach (msg) =>
      ul.appendChild @_renderitem msg
      return
    # console.log ul #, @channel.records
    data = ul.outerHTML
    uri = 'data:text/html;charset=utf-8,' + encodeURIComponent data.replace /\r\n|\r|\n/g, '\n'
    # window.open uri, '_newtab'
    @channel.system "Export HTML Log: [Save As HTML](#{uri} \"Save As HTML\")"
    @
# end of class

# additional events: (before|after)append|scrolled:(scrolltop)|read:(msgts, msgel)

View.reg MsgLog # reg
