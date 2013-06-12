SearchTemplate = require 'views/templates/search'
ResultView = require 'views/result_view'
module.exports = class SearchView extends Backbone.View

  id: 'search-page'

  initialize: ->
    @listenTo @collection, 'reset', @renderResults
    @listenTo @collection, 'search:started', @showThrobber
    @listenTo @collection, 'search:complete', @hideThrobber
    # Track where on search page the user has scrolled.
    @listenTo app.eventBus, 'distance:scrollTop', (scrollTop) =>
      @collection.scrollTop = scrollTop

  events:
    'click button': 'search'
    'keypress input': 'searchByEnter'

  render: ->
    @$el.html SearchTemplate()

    @renderResults()
    _.defer =>
      @$('input').val(@collection.query_str)
      @$('input').focus()
      if @collection.scrollTop?
        $(window).scrollTop(@collection.scrollTop)
    @

  renderResults: ->
    @$('#search-results').empty()
    # Show how many results + how long the search took.
    if @collection.total? and @collection.searchtime?
      @$('.search-meta').html "#{ @collection.total } results (#{ @collection.searchtime / 1000 } seconds)"
    else
      @$('.search-meta').empty()
    if @collection.length
      @$('.js-loading').hide()
      for result in @collection.models
        @addChildView = resultView = new ResultView model: result
        @$('#search-results').append resultView.render().el
    # Only show no matches if a search was done, e.g. if just rendering the search
    # page, don't show this.
    else if @collection.total is 0
      @$('#search-results').html '<h4>No matches</h4>'
      @$('.js-loading').hide()
    @

  search: ->
    query = @$('input').val()
    unless query is ""
      @collection.query(query)
      app.router.navigate('/search/' + encodeURIComponent(query))

  # Show throbber to show activity during long queries.
  showThrobber: ->
    @$('.js-loading').css('display', 'inline-block')

  hideThrobber: ->
    @$('.js-loading').hide()

  searchByEnter: (e) ->
    if e.which is 13 then @search()
