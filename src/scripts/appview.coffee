# imported by views.coffee

# base view class
import 'view'
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
    super()
    if localStorage.transition isnt 'off' # tmp
      document.documentElement.className += 'transition'
    # init views
    @login.init()
    # @chat.init() # chat init after login
    @

View.reg AppView # reg
