# Routing keyboard shortcuts.
key 's,/', => app.router.navigate('search', true)
key 'h', => app.router.navigate('', true)
key 'n', => app.router.newPost(true, true)

# Move around PostsView
#key('j', -> @scrollNext())
#key('k', -> @scrollPrevious())

$(document).on 'keydown', 'textarea, input', (e) ->
  if e.which is 27
    $(e.currentTarget).blur()

$(document).on 'keydown', (e) ->
  if ($(e.target).is('input, textarea, select')) then return # Ignore keystrokes within input elements.
  app.eventBus.trigger 'keydown', e.which

# Scroll to the top of the page when someone presses "g" twice within a second.
app.eventBus.on 'keydown', (keycode) ->
  if keycode is 71 # "g"
    do ->
      # Create a callback function so we can easily remove it from
      # the eventBus after a second.
      callback = (keycode) ->
        if keycode is 71
          $("html, body").animate({ scrollTop: 0 })

      # Listen for keycodes.
      app.eventBus.on 'keydown', callback

      # After a second, stop listening.
      _.delay (-> app.eventBus.off 'keydown', callback), 1000
