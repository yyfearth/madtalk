div '#login', hidden: true, -> form action: '#', method: 'POST', ->
  fieldset ->
    legend 'Login'
    label for: 'nick', 'Nickname'
    input '#nick',
      name: 'nick'
      type: 'text'
      value: ''
      placeholder: 'Nickname'
      autofocus: on
      required: on
      maxlength: 32
    input
      type: 'submit'
      value: 'Join'
      pattern: /^[^\x00-\x17\x7f<">]{3,30}$/
      maxlength: 30
