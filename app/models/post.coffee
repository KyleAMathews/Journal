class exports.Post extends Backbone.Model

  initialize: ->
    @set rendered: marked(@get('body'))
