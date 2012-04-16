exports.RegionManager =

  # Displays a backbone view instance inside of the region.
  # Handles calling the `render` method for you. Reads content
  # directly from the `el` attribute. Also calls an optional
  # `onShow` and `close` method on your view, just after showing
  # or just before closing the view, respectively.
  show: (view) ->
    oldView = @currentView
    @currentView = view

    @_closeView oldView
    @_openView view

    app.eventBus.trigger('pane:show')

  _closeView: (view) ->
    if view && view.close
      view.close()

  _openView: (view) ->
    @$el.html view.render().el
    if view.onShow
      view.onShow()
