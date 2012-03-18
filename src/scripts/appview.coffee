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
    _trans = localStorage.transition
    if _trans isnt 'off' # tmp
      el = document.documentElement
      el.className += ' transition'
      el.className += ' fast' if _trans is 'fast' # tmp
    # document.body.onresize = =>
    #   if @height isnt (h = window.innerHeight)
    #     console.log h, @height
    #     alert 'resize ' + h
    #     @el.style.height = h + 'px'
    #   return
    # document.addEventListener 'touchmove', (e) ->
    #   if e.target is document.body
    #     e.preventDefault()
    #     false
    # , false
    # init views
    @login.init()
    # @chat.init() # chat init after login
    @

View.reg AppView # reg
