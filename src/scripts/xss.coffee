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
    '0': '\x00'
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
        ch = ch[1..] # remove ^\
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
