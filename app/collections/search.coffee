Result = require 'models/result'
module.exports = class Search extends Backbone.Collection

  model: Result

  initialize: ->
    @fetchCommonQueries()
    @on 'search:complete', => @fetchCommonQueries()

  fetchCommonQueries: ->
    $.getJSON '/search/queries', (data) =>
      @queries = data

  query: (query) ->
    unless query is ""
      @trigger 'search:started'
      @query_str = query
      start = new Date()
      @reset()
      app.util.search query, (results) =>
        @results = results
        @searchtime = new Date() - start
        @total = results.hits.total
        @max_score = results.hits.max_score
        @reset(results.hits.hits)
        console.log results.facets
        for entry in results.facets.year.entries
          year = moment.utc(entry.time).year()
          console.log year + ": " + entry.count
          console.log ''
        for entry in results.facets.month.entries
          year = moment.utc(entry.time).format('MMMM YYYY')
          console.log year + ": " + entry.count

        @trigger 'search:complete'

    else
      @clear()

  # Remove my various bits of state.
  clear: ->
    @results = null
    @searchtime = null
    @max_score = null
    @total = null
    @query_str = null
    @scrollTop = null
    @reset()
