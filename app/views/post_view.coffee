PostTemplate = require 'views/templates/post'
class exports.PostView extends Backbone.View

  className: 'post'

  render: =>
    @model.set rendered_body: marked(@model.get('body'))
    @model.set rendered_created: moment(@model.get('created')).format("dddd, MMMM Do YYYY")
    data = @model.toJSON()
    if @options.page
      data.page = true
    @$el.remove()
    @$el.html PostTemplate data
    @
