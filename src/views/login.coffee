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
      pattern: "^[^\\x00-\\x17\\x22\\x3c\\x3e\\x7f]{3,30}$"
      maxlength: 32
    input
      type: 'submit'
      value: 'Join'
