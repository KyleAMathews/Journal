PostTemplate = require 'views/templates/post'
class exports.PostView extends Backbone.View

  className: 'post'

  initialize: ->
    @debouncedRender = _.debounce @render, 25
    @listenTo @model, 'change', @debouncedRender

    window.post = @

  events:
    'dblclick': 'doubleclick'

  render: =>
    if @model.get('body') isnt "" and @model.get('title') isnt ""
      @model.renderThings(true)
      data = @model.toJSON()
      if @options.page
        data.page = true
      @$el.html PostTemplate data
    else
      @$el.html "<h2>Loading post... #{ app.templates.throbber('show', '32px') }</h2>"

    # Make external links open in new tab
    @$("a[href^=http]").each ->
      if @href.indexOf(location.hostname) is -1
        $(@).attr target: "_blank"

    @$("img").each ->
      el = $(@)
      if _.str.include el.attr('src'), 'attachments'
        $(@).wrap("<a target='_blank' href='#{ el.attr('src') + "/original" }' />")
    @

  doubleclick: ->
    app.router.navigate "/node/#{ @model.get('nid') }/edit", true
