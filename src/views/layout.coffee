doctype 5
html ->
  head ->
    meta charset: 'utf-8'

    title "#{@title} - MadTalk" if @title?
    meta(name: 'description', content: @description) if @description?
    link(rel: 'canonical', href: @canonical) if @canonical?

    if @dev
      style @css
      # script src: '/socket.io/socket.io+websocket.js'
    else
      link(rel: 'apple-touch-icon', href: 'madtalk_ios_icon.png')

      meta(name:'viewport', content:'width=device-width, initial-scale=1, user-scalable=no')
      meta(name:'apple-mobile-web-app-capable', content:'yes')
      
      link rel: 'icon', href: '/favicon.ico'
      link rel: 'stylesheet', href: "/client.css?#{@ts}"
    
    # coffeescript -> $ -> alert 'hi!'

  body ->
    # header ->

    div '#app', -> @body

    # footer ->
      # p -> a href: '/privacy', -> 'Privacy Policy'
