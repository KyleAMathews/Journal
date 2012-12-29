SearchTemplate = require 'views/templates/search'
ResultView = require 'views/result_view'
module.exports = class SearchView extends Backbone.View

  id: 'search-page'

  initialize: ->
    @listenTo @collection, 'reset', @renderResults

  events:
    'click button': 'search'
    'keypress input': 'searchByEnter'

  render: ->
    console.log 'rendering search page'
    @$el.html SearchTemplate()
    @$('input').val(@collection.query_str)

    @renderResults()
    _.defer =>
      @$('input').focus()
    @

  renderResults: ->
    @$('#search-results').empty()
    # Show how many results + how long the search took.
    if @collection.total? and @collection.searchtime?
      @$('.search-meta').html "#{ @collection.total } results (#{ @collection.searchtime / 1000 } seconds)"
    else
      @$('.search-meta').empty()
    if @collection.length
      @$('.loading').hide()
      for result in @collection.models
        @addChildView = resultView = new ResultView model: result
        @$('#search-results').append resultView.render().el
    # Only show no matches if a search was done, e.g. if just rendering the search
    # page, don't show this.
    else if @collection.total is 0
      @$('#search-results').html '<h4>No matches</h4>'
      @$('.loading').hide()
    @

  search: ->
    query = @$('input').val()
    unless query is ""
      # Show ajax loader gif for long queries.
      @$('.loading').show()
      @collection.query(query)
      app.router.navigate('/search/' + encodeURIComponent(query))

  searchByEnter: (e) ->
    if e.which is 13 then @search()
