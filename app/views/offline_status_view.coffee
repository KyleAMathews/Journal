module.exports = class OfflineStatusView extends Backbone.View

  initialize: ->
    @listenTo app.state, 'change:online', @toggleOnlineStatus
    @render()

  render: ->
    if $(document).width() > 650
      @$el.html("App is offline. All changes made while offline will be saved to the server once you reconnect.")
    else
      @$el.html("App is offline")
    @

  toggleOnlineStatus: (model, online) ->
    if online
      @$el.transition({ y: '0' }, => @$el.css('top', '-3em'))
      $('#wrapper').transition({ y: '0' })
    else
      @$el.css('top', 0).transition({ y: '3em' })
      $('#wrapper').transition({ y: '3em' })
