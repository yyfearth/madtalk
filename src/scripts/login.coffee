# imported by views.coffee

class Login extends View
  type: 'login'
  constructor: (@cfg) ->
    # PLEASE USE View.create 'login', cfg instead of new
    Object.defineProperties @, # form value shotcuts
      nick: get: -> @form?.nick.value
    console.log 'constructor login'
    super @cfg # with auto init
  # end of constructor

  ### static ###
  @create: (cfg) -> super @, cfg
  ### public ###
  init: ->
    super()
    @form = @el.querySelector 'form'
    @form.onsubmit = (e) =>
      e.preventDefault()
      @login nick: @nick
      false
    # end of form submit
    if @channel.user?.nick
      # auto login
      console.log 'auto login', @channel.user.nick
      @login null
    else
      console.log 'show login form'
      @show yes
    @
  # end of init
  login: (user) ->
    @channel.user = user if user?.nick
    @channel.login (err) =>
      if err
        alert 'login failed'
      else
        @show off
      return
    @
  # end of login

