PostTemplate = require 'views/templates/post'
class exports.PostView extends Backbone.View

  className: 'post'

  events:
    'dblclick': 'doubleclick'

  render: =>
    unless @model.get('rendered_body')? and @model.get('rendered_created')?
      @model.renderThings()
    data = @model.toJSON()
    if @options.page
      data.page = true
    @$el.html PostTemplate data

    # Make external links open in new tab
    @$("a[href^=http]").each ->
      if @href.indexOf(location.hostname) is -1
        $(@).attr target: "_blank"
    @

  doubleclick: ->
    app.router.navigate "/node/#{ @model.get('nid') }/edit", true
