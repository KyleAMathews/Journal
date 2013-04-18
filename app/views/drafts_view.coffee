DraftsTemplate = require 'views/templates/drafts'

module.exports = class DraftsView extends Backbone.View

  className: "drafts-page"

  initialize: ->
    @listenTo @collection, 'reset', @render

  events:
    'click li': 'gotoDraftEditPage'

  render: ->
    @$el.html DraftsTemplate()
    @addAll()
    @

  addAll: ->
    for draft in @collection.models
      @$('ul').append("<li class='link link-color' data-draft-id='#{ draft.get('id')}'>#{ draft.get 'title' } <em>#{ moment(draft.get('created')).fromNow() }</em></li>")

  gotoDraftEditPage: (e) ->
    draftId = $(e.target).closest('li').data('draft-id')
    app.router.navigate('drafts/' + draftId, true)
