# imported by panel.coffee

class StatusBar extends View
  type: 'status'
  constructor: (@cfg) ->
    super @cfg # with auto init
  ### static ###
  @create: (cfg) -> super @, cfg
  ### public ###
  init: ->
    super()
    @nick = @query '#user-nick'
    @list = @query '#users-list'
    @conn = @query '#conn-status'
    @mode = @query '#msg-mode'
    @type = @query '#msg-type'
    # todo: cmd mode and trigger modes
    @_text @mode, 'markdown'
    @_text @type, 'gfm'
    # check add permition button
    @_check()
    @
  _text: (el, txt) ->
    el[if el.innerText? then 'innerText' else 'textContent'] = txt
  _check: ->
    return unless (api = window.webkitNotifications)?.checkPermission() > 0
    li = document.createElement 'li'
    btn = document.createElement 'input'
    btn.type = 'button'
    btn.value = 'Allow Desktop Notifications'
    btn.onclick = ->
      api.requestPermission =>
        @parentNode.removeChild @
    li.appendChild btn
    @el.appendChild li
    console.log 'check', li, @el
    @
  # end of check
  update: ->
    return @ unless @init
    # user nick
    @_text @nick, @channel.user.nick
    # users list
    online_u = 0 #@channel.users.filter (u) -> u.status isnt 'offline'
    @list.title = @channel.users.map((u) ->
      online_u++ if u.status isnt 'offline'
      "* #{u.nick} #{u.status}").join '\n'
    @_text @list, @list.counter = "#{online_u} / #{channel.users.length}"
    @list.onclick ?= =>
      @channel.system "*Users in this channel #{@list.counter}*\n\n#{@list.title}"
      false
    @
  online: (online = on) ->
    @_text @conn, if online then 'online' else 'offline'
    @
# end of class

View.reg StatusBar # reg
