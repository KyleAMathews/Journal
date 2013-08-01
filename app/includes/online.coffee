class Online
  constructor: ->
    app.state.on 'change:online', (model, online) =>
      console.log 'online state changed', online
      # If we go offline, try pinging the server every 15 seconds until we detect
      # we've reconnected.
      if online
        clearInterval(@id)
      else
        #@ping()
        @id = setInterval(@ping, 1500)

  ping: =>
    $.ajax
      url: '/ping'
      success: (result) ->
        console.log result
        app.state.set 'online', true
      error: (result) ->
        console.log result
        app.state.set 'online', false

new Online()
