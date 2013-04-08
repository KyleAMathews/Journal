Result = require 'models/result'
module.exports = class Search extends Backbone.Collection

  model: Result

  query: (query) ->
    @trigger 'search:started'
    @query_str = query
    start = new Date()
    @reset()
    unless query is ""
      app.util.search query, (results) =>
        @searchtime = new Date() - start
        @total = results.hits.total
        @max_score = results.hits.max_score
        @reset(results.hits.hits)
        for entry in results.facets.year.entries
          year = moment.utc(entry.time).year()
          console.log year + ": " + entry.count

        @trigger 'search:complete'

    else
      @clear()

  # Remove my various bits of state.
  clear: ->
    @reset()
    @searchtime = null
    @max_score = null
    @total = null
    @query_str = null
