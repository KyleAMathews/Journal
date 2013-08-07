class Online
  constructor: ->
    # TODO verify actual event name.
    document.addEventListener("onLineChange", @ping)

    app.state.on 'change:online', (model, online) =>
      console.log 'online state changed', online
      # If we go offline, try pinging the server every 15 seconds until we detect
      # we've reconnected.
      if online
        clearInterval(@id)
      else
        @ping()
        @pingWait = 1000
        setTimeout(@ping, @pingWait)

  ping: =>
    @lastPing = new Date()
    $.ajax
      url: '/ping'
      success: (result) =>
        app.state.set 'online', true
      error: (result) =>
        app.state.set 'online', false
        # Back off interval between pings until two minutes.
        unless @pingWait >= 120000
          @pingWait = @pingWait * 1.5
        else
          @pingWait = 120000
        setTimeout(@ping, @pingWait)

new Online()
