class Online
  constructor: ->
    # Check on app load if we're actually online or not.
    @ping()

    # TODO verify actual event name.
    document.addEventListener("onLineChange", @ping)

    app.state.on 'change:online', (model, online) =>
      console.log 'online state changed', online
      # If we go offline, try pinging the server until we detect
      # we've reconnected.
      unless online
        @pingWait = 1000
        @ping()

  ping: =>
    @lastPing = new Date()
    $.ajax
      url: '/ping'
      success: (result) =>
        @pingWait = 1000
        app.state.set 'online', true
      error: (result) =>
        app.state.set 'online', false

        # Back off interval between pings until the interval reaches two minutes.
        unless @pingWait >= 120000
          @pingWait = @pingWait * 1.5
        else
          @pingWait = 120000
        setTimeout(@ping, @pingWait)

new Online()
