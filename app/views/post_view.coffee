PostTemplate = require 'views/templates/post'
class exports.PostView extends Backbone.View

  tagName: 'li'
  className: 'post'

  render: ->
    @$el.html PostTemplate @model.toJSON()
    @
