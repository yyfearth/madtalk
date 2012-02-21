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
    input type: 'submit', value: 'Join'
