# madtalk client.coffee

import './class/Login'

channel = io.connect '/0'

try
  user = sessionStorage.user
  if user
    user = JSON.parse user
    throw 'bad user session data' unless user?.nick
  else
    user = null
catch e
  console.error 'bad user session data', e
  user = null

xss_safe = # by Wilson Young under MIT License
  #remove_regex: /on\w{1,20}?=|javascript:/ig # prevent attr injection
  replace_regex: /<|>/g # prevent html esp script
  replace_dict:
    '&': '&amp;'
    '<': '&lt;'
    '>': '&gt;'
    '"': '&quot;'
    "'": '&#x27;' # &apos; is not recommended
    '/': '&#x2F;' # forward slash is included as it helps end an HTML entity
  esc_regex: /\\[\/\\nbtvfr'"0(u\w{4})(x\w{2})]/g
  esc_dict:
    '\\': '\\'
    '\/': '\/'
    '"': '"'
    "'": "'"
    '0': '\x0'
    'n': '\n'
    'b': '\b'
    't': '\t'
    'v': '\v'
    'f': '\f'
    'r': '\r'
  url: (url) -> encodeURI url # todo:
  attr: (str) ->
    # str.replace /[\n'"]/g, '\\$0'
    str.toString()
      #.replace @remove_regex, ''
      .replace /\W/g, (ch) ->
        s = ch.charCodeAt(0)
        ch = if s < 255 then "&##{s};" else ch
  js: (str, noesc) -> # noesc = true if there are no \n like in str
    #.replace /\\./, '' todo: \b \n
    if not noesc
      str = str.replace @esc_regex, (ch) =>
        ch = ch.slice 1 # remove ^\
        if @esc_dict[ch]?
          @esc_dict[ch]
        else
          String.fromCharCode Number ch.clice 1
    str.replace /\W/g, (ch) ->
      s = ch.charCodeAt(0)
      if s < 255
        s = s.toString 16
        s = '0' + s if s.length < 2
        '\\x' + s
      else
        ch
  str: (str) -> # str should be a string
    str.toString().replace @replace_regex, (p) => @replace_dict[p]
  json: (json, parse) -> # str is string or json obj, parse = true if need to parse json obj back
    is_str = typeof json is 'string'
    json = JSON.stringify json if not is_str
    json = @str json
    if is_str or not parse then json else JSON.parse json

_log = null
add_log = (recs) ->
  recs = [recs] unless Array.isArray recs
  recs = recs.map (rec) ->
    "<li>#{xss_safe.str rec.user.nick} - #{new Date(rec.ts).toLocaleTimeString()}<br/>#{xss_safe.str(rec.data).replace /\n/g, '<br/>'}</li>"
  
  _log.append recs.join '\n'
  return

do_login = (user) ->
  console.log 'do_login', user
  channel.emit 'login', user, (upduser, records) -> # updated user profile

    if upduser.err
      console.error upduser
    else
      console.log 'logined', upduser
      user.uid = upduser.uid

      channel.el = document.querySelector '#channel'
      channel.el.hidden = false
      # show

      channel.on 'online', (user) ->
        console.log 'online', user

      channel.on 'offline', (user) ->
        console.log 'offline', user

      channel.on 'message', (data) ->
        console.log 'got message', data
        add_log data

      channel.message = (data) ->
        channel.emit 'message', data, (ok) ->
          if ok
            console.log 'message sent', data
          else
            console.error data

      window.onbeforeunload = ->
        sessionStorage.user = JSON.stringify user
        'sure to exit?'

      $('#entry').keydown (e) ->
        if e.keyCode is 13 and not (e.ctrlKey or e.metaKey or e.shiftKey or e.altKey)
          channel.message type: 'text', data: @value
          @value = ''
          false

      _log.empty()
      add_log records

      return
    # end of emit login
  return

login = new Login el: '#login', user: user, logined: do_login

window.channel = channel

channel.on 'connect', ->
  console.log 'connected'
  $ -> # dom ready, todo: wait for conn
    console.log 'domready'
    $('#conn-status').text 'online'

    _log = $ '#log'

    channel.on 'system', (data) ->
      console.log 'got system message', data

    login.init() unless login.inited

channel.on 'disconnect', ->
  $('#conn-status').text 'offline'
