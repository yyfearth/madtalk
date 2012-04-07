# imported by views.coffee

# base view class
import 'view'
import 'popupview'
# sub views
import 'login'
import 'chat'

class AppView extends View
  type: 'app'
  constructor: (@cfg) ->
    super @cfg # with auto init
    @login = Login.create el: '#login'
    @chat = Chat.create el: '#chat'
  ### static ###
  @create: (cfg) -> super @, cfg
  ### public ###
  init: ->
    _trans = localStorage.transition
    if _trans is 'off' # tmp
      Popup::fade = 0
    else
      el = document.documentElement
      el.className += ' transition'
      el.className += ' fast' if _trans is 'fast' # tmp
    super()
    # init views
    @login.init()
    # @chat.init() # chat init after login
    @

View.reg AppView # reg
