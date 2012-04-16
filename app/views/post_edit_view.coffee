PostEditTemplate = require 'views/templates/edit_post'
class exports.PostEditView extends Backbone.View

  className: 'post-edit'

  render: ->
    @$el.html PostEditTemplate @model.toJSON()
    @
