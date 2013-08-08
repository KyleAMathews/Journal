class Online
  constructor: ->
    # Check on app load if we're actually online or not.
    @pingWait = 1000
    @ping()

    document.addEventListener('online',  @ping)
    document.addEventListener('offline',  @ping)

    app.state.on 'change:online', (model, online) =>
      # If we go offline, try pinging the server until we detect
      # we've reconnected.
      unless online
        @ping()

    # Don't check if app is online unless it's visible (but immediately
    # check once person returns to tab).
    app.eventBus.on 'visibilitychange', (state) =>
      unless app.state.isOnline()
        if state is "visible"
          @ping()
        else
          clearTimeout(@id)

  ping: =>
    @lastPing = new Date()
    clearTimeout(@id)

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
        @id = setTimeout(@ping, @pingWait)

app.online = new Online()
