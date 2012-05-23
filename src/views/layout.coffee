doctype 5
html ->
  head ->
    meta charset: 'utf-8'

    title "#{@title} - MadTalk" if @title?
    meta(name: 'description', content: @description) if @description?
    link(rel: 'canonical', href: @canonical) if @canonical?

    meta(name:'viewport', content:'width=device-width, initial-scale=1, user-scalable=no')
    meta(name:'apple-mobile-web-app-capable', content:'yes')

    if @dev
      style @css
    else
      link rel: 'icon', href: '/favicon.ico'
      link rel: 'stylesheet', href: "/client.css?#{@ts}"
      #script src: '/socket.io/socket.io.js', defer: on
    
    # coffeescript -> $ -> alert 'hi!'

  body ->
    # header ->

    div '#app', -> @body

    # footer ->
      # p -> a href: '/privacy', -> 'Privacy Policy'
