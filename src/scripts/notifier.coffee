import 'notifier-res'
import 'desk-notifier'

class Notifier
  constructor: ->
    @queue = []
    _active = false
    Object.defineProperties @,
      active:
        get: -> _active
        set: (value) ->
          _active = value
          @activate value
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
  activate: (active = yes) ->
    if active
      @_title = document.title or @title or 'MadTalk'
    else
      document.title = @_title
      @queue = []
    @
  audioNotify: (args...) ->
    return if localStorage.muted
    @static.audioNotify args...
    @
  titleNotify: ->
    document.title = "(#{@queue.length} New Message ... ) - MadTalk"
    @
  deskNotify: (msg) ->
    DeskNotifier.notify
      #iconPath: 'https://developer.mozilla.org/favicon.ico'
      title: "Message from #{msg.user?.nick or 'System'}"
      content: if msg.data.length > 200 then msg.data[0..200] + '...' else msg.data
      timeout: 15000 # 15s
      click2Close: => @onfocus?()
  onfocus: -> # can be override
    window.focus()
    @
  notify: (msg) ->
    return @ unless @active
    console.log 'notifier', @active
    @queue.push msg
    @audioNotify()
    @titleNotify()
    @deskNotify msg
    @
