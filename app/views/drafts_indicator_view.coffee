module.exports = class DraftsIndicatorView extends Backbone.View

  initialize: ->
    @listenTo @collection, 'all', @update

  events:
    'click': 'toggleDropdown'
    'click .dropdown li': 'gotoDraftEditPage'

  render: ->
    @update()

  update: ->
    @$('.count').html @collection.length
    @renderDrafts()
    if @collection.length > 0
      @$el.addClass 'active'
    else
      @$el.removeClass 'active'

  renderDrafts: ->
    @$('ul.dropdown').empty()
    for draft in @collection.models
      @$('ul.dropdown').append("<li data-draft-id='#{ draft.get('id')}'>#{ draft.get 'title' } <em>#{ moment(draft.get('created')).fromNow() }</em></li>")

  toggleDropdown: ->
    if @collection.length > 0
      @renderDrafts()
      @$el.toggleClass('dropdown-active')

  gotoDraftEditPage: (e) ->
    draftId = $(e.target).closest('li').data('draft-id')
    app.router.navigate('draft/' + draftId, true)
