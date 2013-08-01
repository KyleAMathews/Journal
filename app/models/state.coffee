module.exports = class State extends Backbone.Model

  defaults:
    online: true

  initialize: ->
    app.eventBus.on 'online', (state) =>
      @set online: state
