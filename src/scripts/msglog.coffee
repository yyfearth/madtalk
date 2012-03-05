# imported by views.coffee

import 'lib/pagedown.js'
import 'lib/highlight.pack.js'
import 'lib/highlight-coffee.js'

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
    default: # http://webreflection.blogspot.com/2012/02/js1k-markdown.html
      `function markdown(f){/*!(C) WebReflection*/for(var b="</code></pre>",c="blockquote>",e="(?:\\r\\n|\\r|\\n|$)",d="(.+?)"+e,a=[],h=["&(?!#?[a-z0-9]+;)","&amp;","<","&lt;",">","&gt;","^(?:\\t| {4})"+d,function(i,j){return a.push(j+"\n")&&"\0"},"^"+d+"=+"+e,"<h1>$1</h1>\n","^"+d+"-+"+e,"<h2>$1</h2>\n","^(#+)\\s*"+d,function(i,l,k,j){return"<h"+(j=l.length)+">"+k.replace(/#+$/,"")+"</h"+j+">\n"},"(?:\\* \\* |- - |\\*\\*|--)[-*][-* ]*"+e,"<hr/>\n","  +"+e,"<br/>","^ *(\\* |\\+ |- |\\d+. )"+d,function(i,l,k,j){return"<"+(j=/^\d/.test(l)?"ol>":"ul>")+"<li>"+markdown(k)+"</li></"+j},"</(ul|ol)>\\s*<\\1>","","([_*]{1,2})([^\\2]+?)(\\1)",function(i,l,k,j){return"<"+(j=l.length==2?"strong>":"em>")+k+"</"+j},"\\[(.+?)\\]\\((.+?) (\"|')(.+?)(\\3)\\)",'<a href="$2" title="$4">$1</a>',"^&gt; "+d,function(i,j){return"<"+c+markdown(j)+"</"+c},"</"+c+"\\s*<"+c,"","(\x60{1,2})([^\\r\\n]+?)\\1","<code>$2</code>","\\0",function(i){return"<pre><code>"+a.shift()+b},b+"\\s*<pre><code>",""],g=0;g<h.length;){f=f.replace(RegExp(h[g++],"gm"),h[g++])}return f}`
    text: (data) -> @xss.str(data).replace /\n/g, '<br/>'
    md: Markdown.md
    gfm: Markdown.gfm
  render: ({type, data}) ->
    #throw "unknown type to render #{type}" unless @renderers.hasOwnProperty type
    type = 'default' unless @renderers.hasOwnProperty type
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
