PostTemplate = require 'views/templates/post'
class exports.PostView extends Backbone.View

  className: 'post'

  render: ->
    data = @model.toJSON()
    if @options.page
      data.page = true
    @$el.html PostTemplate data
    @
