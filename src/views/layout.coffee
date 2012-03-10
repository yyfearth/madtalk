doctype 5
html ->
  head ->
    meta charset: 'utf-8'

    title "#{@title} - MadTalk" if @title?
    meta(name: 'description', content: @description) if @description?
    link(rel: 'canonical', href: @canonical) if @canonical?

    if @dev
      style @css
    else
      link rel: 'icon', href: '/favicon.ico'
      link rel: 'stylesheet', href: '/client.css'
      #script src: '/socket.io/socket.io.js', defer: on
      script src: 'client.js', defer: on
    
    # coffeescript -> $ -> alert 'hi!'

  body ->
    # header ->

    div '#app', -> @body

    # footer ->
      # p -> a href: '/privacy', -> 'Privacy Policy'
    
    if @dev
      # script src: '/socket.io/socket.io+websocket.js'
      script @js # client.js
