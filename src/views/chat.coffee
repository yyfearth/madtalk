div '#chat', hidden: 'hidden', ->
  ul '#msglog', ->
    li '.log', -> '(none)'
  div '#panel', ->
    ul '#status', ->
      li -> a '#user-nick', title: 'your nickname', -> '(nickname)'
      li -> a '#conn-status', title: 'current status', -> 'offline'
      li -> a '#users-list', title: 'online / users', -> '(none)'
      li ->
        a '#msg-mode', title: 'Mode', -> '(default mode)'
        text ': '
        a '#msg-type', title: 'Type', -> '(default type)'
      li -> span hidden: true, ->
        text 'Channel Uptime: '
        a '#uptime', -> '0s'
      li -> a '#reload', title: 'reload app', onclick: 'if(confirm(\'reload?\'))location.reload()', -> 'reload'
    div '#preview', hidden: 'hidden'
    textarea '#entry',
      rows: 1
      maxlength: 30000
      autofocus: on
      placeholder: '_'
