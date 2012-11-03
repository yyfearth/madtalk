# imported by chat.coffee
import 'highlight.pack.js'
import 'marked.js'

# set default options
marked.setOptions
  gfm: true
  pedantic: false
  sanitize: true
  # callback for code highlighter
  # highlight: (code, lang) -> # hljs need dom not text
  #   hljs.highlightBlock code, null, true # (code.parentNode.tagName isnt 'PRE')

window.marked = marked
window.hljs = hljs
