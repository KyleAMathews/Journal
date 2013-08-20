PostTemplate = require 'views/templates/post'
class exports.PostView extends Backbone.View

  className: 'post'

  initialize: ->
    @debouncedRender = _.debounce @render, 25
    @listenTo @model, 'change sync', @debouncedRender
    @listenTo @model, 'destroy', @remove
    @listenTo app.state, 'change:online', (model, online) ->
      # When the app attempts to fetch a model and then detects
      # (due to the model fetch failing) that it's offline, the PostView
      # doesn't seem to ever catch this failed sync. So listen for the app
      # going offline and render.
      unless online
        @render()

    # Unless we're looking at a postView on a single page, set this postView
    # on the model so it's accessible.
    unless @options.page
      @model.view = @

    window.post = @

  events:
    'dblclick': 'doubleclick'
    'click span.starred': 'toggleStarred'

  render: =>
    if @model.get('body') isnt "" and @model.get('title') isnt ""
      @model.renderThings(true)
      data = @model.toJSON()
      if @options.page
        data.page = true
      @$el.html PostTemplate data
    else if not app.state.isOnline()
      @$el.html "<div class='error show'>Sorry, this post can't be loaded while you are offline</div>"
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

  toggleStarred: ->
    if @model.get('starred')
      @model.save('starred', false)
    else
      @model.save('starred', true)
