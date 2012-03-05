import 'notifier-res'

class Notifier
  static: Notifier

  @audios: notifier_sound
  @audioNotify = ->
    throw 'notifier sound res not ready' unless audios?.default?.length
    audio = new Audio
    for mime, data of audios.default
      if audio.canPlayType mime
        audio.src = "data:#{mime};base64,#{data}"
        audio.play()
        return
