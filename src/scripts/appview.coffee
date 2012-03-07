# imported by views.coffee

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
    # init views
    @login.init()
    # @chat.init()
    @

View.reg AppView # reg
