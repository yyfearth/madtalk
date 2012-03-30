import 'notifier-res'
# import 'desk-notifier'

class Notifier
  constructor: ->
    @queue = []
    _active = false
    Object.defineProperties @,
      active:
        get: -> _active
        set: (value) ->
          _active = value
          @_activate value
          return
  ### static ###
  static: Notifier
  @audio_timeout: 1000 # 1s
  @audio_last: 0
  @audios: notifier_sound
  @audioNotify: ->
    ts = new Date().getTime()
    return @ if ts - @audio_last < @audio_timeout
    @audio_last = ts
    @audios.default.muted = no
    @audios.default.play()
    @
  # end of audio notify
  @init: ->
    # audio init
    throw 'notifier sound res not ready' unless @audios?.default?
    audio = new Audio
    for mime, data of @audios.default
      if audio.canPlayType mime
        audio.src = "data:#{mime};base64,#{data}"
        audio.muted = yes
        audio.play()
        # _enable = ->
        #   audio.muted = no
        #   audio.removeEventListener 'ended', _enable
        #   return
        # audio.addEventListener 'ended', _enable, false
        @audios.default = audio
        break

    # init once
    @init = null
    @
  # end of init
  init: ->
    @static.init?()
    @
  audioNotify: (args...) ->
    return if localStorage.muted
    @static.audioNotify args...
    @
  titleNotify: ->
    document.title = "(#{@queue.length} New Message ... ) - MadTalk"
    @
  deskNotify: (msg) ->
    @_desk_notify
      #iconPath: 'https://developer.mozilla.org/favicon.ico'
      title: "Message from #{msg.user?.nick or 'System'}"
      content: if msg.data.length > 200 then msg.data[0..200] + '...' else msg.data
      timeout: 15000 # 15s
      click2close: => @onfocus?()
  onfocus: -> # can be override
    window.focus()
    @active = no
    @
  notify: (msg) ->
    return @ unless @active
    console.log 'notifier', @active
    @queue.push msg
    @audioNotify()
    @titleNotify()
    @deskNotify msg
    @
  ### private ###
  _activate: (active = yes) ->
    console.log 'notifier', active
    if active
      @_title = @title or document.title or 'MadTalk'
    else
      document.title = @_title
      n.cancel() for n in @_desk_list
      @_desk_list = []
      @queue = []
    @
  ###
  Pop out a notification.
  ###
  _api: window.webkitNotifications
  _desk_max: 3
  _desk_list: []
  _desk_notify: ({icon, title, content, timeout, click2close}) ->
    throw 'content is necessary' unless content
    icon ?= ''
    title ?= @title or ''
    timeout = 0 unless timeout? > 0
    # click2close ?= off

    notification = @_api.createNotification icon, title, content
    @_desk_list.push notification

    notification.addEventListener 'close', (e) =>
      index = @_desk_list.indexOf notification
      @_desk_list.splice index, 1 unless index < 0

    # notification.addEventListener 'error', (e) ->
    #   console.log 'error', DeskNotifier.list
    #   index = DeskNotifier.list.indexOf notification
    #   DeskNotifier.list.splice index, 1 if index >= 0

    if click2close
      notification.addEventListener 'click', ->       
        notification.cancel()
        click2close?()
    
    if timeout > 0
      setTimeout ->
        notification.cancel()
      , timeout

    @_desk_list.shift().cancel() while @_desk_list.length > @_desk_max

    notification.show()
    notification

  # _ask_permission: (onAnswered) ->
  #   # return @ if @isEnabled
  #   # console.log 'ask p'

  #   @api.requestPermission =>
  #     # console.log 'ask p', @isEnabled
  #     onAnswered? @isEnabled
  #     return
  #   @
