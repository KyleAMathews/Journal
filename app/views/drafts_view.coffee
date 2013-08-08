DraftsTemplate = require 'views/templates/drafts'

module.exports = class DraftsView extends Backbone.View

  className: "drafts-page"

  initialize: ->
    @listenTo @collection, 'sync:drafts', @render

  events:
    'click a': 'clickHandler'

  render: ->
    @$el.html DraftsTemplate()
    @addAll()
    @

  addAll: ->
    for draft in @collection.getDrafts()
      @$('ul').append("<li class='link'><a href='node/#{ draft.get('nid') }/edit'>#{ draft.get 'title' } <em>#{ moment(draft.get('created')).fromNow() }</em></a></li>")

  clickHandler: (e) ->
    e.preventDefault()
    href = $(e.currentTarget).attr('href')
    app.router.navigate(href, {trigger: true})

