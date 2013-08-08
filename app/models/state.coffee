module.exports = class State extends Backbone.Model

  isOnline: ->
    return @get('online') or _.isUndefined @get('online')
