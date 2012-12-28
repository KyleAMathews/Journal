PostTemplate = require 'views/templates/post'
class exports.PostView extends Backbone.View

  className: 'post'

  render: =>
    unless @model.get('rendered_body')?
      @model.set rendered_body: marked(@model.get('body'))
    unless @model.get('rendered_created')?
      @model.set rendered_created: moment(@model.get('created')).format("dddd, MMMM Do YYYY")
    data = @model.toJSON()
    if @options.page
      data.page = true
    @$el.remove()
    @$el.html PostTemplate data

    # Make external links open in new tab
    @$("a[href^=http]").each ->
      if @href.indexOf(location.hostname) is -1
        $(@).attr target: "_blank"
    @
