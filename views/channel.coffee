div '#channel', hidden: 'hidden', ->
  ul '#log', ->
    li '.msg', -> '(none)'
  div '#toolbar', ->
    ul '#status', ->
      li -> a '#user-nick', title: 'your nickname', -> '(nickname)'
      li -> a '#conn-status', title: 'current status', -> 'offline'
      li -> a '#users-list', title: 'online / users', -> '(none)'
      li -> a '#msg-type', title: 'GitHub Flavored Markdown', -> 'GFM'
      li -> span hidden: true, ->
        text 'Channel Uptime: '
        a '#uptime', -> '0s'
    textarea id: 'entry', rows: 1, maxlength: 10000
