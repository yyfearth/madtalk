
class Popup extends View
  container_el: '#popups'
  mask_el: '#mask'
  fade: 300 # according to cls style
  constructor: (@cfg) ->
    @container_el = @cfg.container_el if @cfg.container_el
    @mask_el = @cfg.mask_el if @cfg.mask_el
    @fade = f >>> 0 if (f = @cfg.fade)? && f isnt true
    super @cfg

  init: ->
    c = @container_el = @query c if typeof (c = @container_el) is 'string'
    @mask_el = @query m, c if typeof (m = @mask_el) is 'string'
    super()
    @

  _set_hidden: (value) -> # override
    console.log 'hidden', value
    return if false is @trigger "before#{if value then 'show' else 'hide'}", @
    @mask_el.style.opacity = if value then 0 else 0.99
    if value
      console.log 'fade', @fade
      @hiding = true # set flag
      @wait @fade, ->
        console.log 'hidden delayed', value
        @el.hidden = yes
        @container_el.style.display = @el.style.display = 'none'
        delete @hiding # rm flag
        @trigger "after#{if value then 'show' else 'hide'}", @
    else
      @container_el.style.display = 'table'
      @el.hidden = no
      @el.style.display = 'inline-block'
      @trigger "after#{if value then 'show' else 'hide'}", @
    return
  # end of override set hidden