div '#channel', hidden: 'hidden', ->
  ul '#log', ->
    li '.msg', -> '(none)'
  div '#toolbar', ->
    ul '#status', ->
      li -> a '#conn-status', -> 'offline'
      li -> a '#users-list', -> '(none)'
      li ->
        text 'Channel Uptime: '
        a '#uptime', -> '0s'
    textarea id: 'entry', rows: 1
