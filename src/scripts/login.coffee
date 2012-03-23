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
      @login null, yes
    else
      console.log 'show login form'
      document.title = "Login - MadTalk"
      @show yes
    @
  # end of init

  login: (user, is_auto) ->
    @channel.user = user if user?.nick # if has input nick
    @channel.login (err) =>
      if err
        @show on
        alert 'login failed!\n' + err if is_auto isnt yes
      else
        @show off
      return
    @
  # end of login

View.reg Login # reg
