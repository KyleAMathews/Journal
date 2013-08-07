module.exports = class OfflineStatusView extends Backbone.View

  initialize: ->
    @listenTo app.state, 'change:online', @toggleOnlineStatus
    @render()

  render: ->
    @$el.show().transition({ y: '-3em' }, 0)
    if $(document).width > 650
      @$el.html("App is offline. All changes made in offline mode will be synced with the server once you reconnect.")
    else
      @$el.html("App is offline")
    @

  toggleOnlineStatus: (model, online) ->
    if online
      @$el.transition({ y: '-3em' })
      $('#wrapper').transition({ y: '0' })
    else
      @$el.transition({ y: 0 })
      $('#wrapper').transition({ y: '3em' })
