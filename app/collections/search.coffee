Result = require 'models/result'
module.exports = class Search extends Backbone.Collection

  model: Result

  query: (query) ->
    @query_str = query
    start = new Date()
    @reset()
    unless query is ""
      app.util.search query, (results) =>
        @searchtime = new Date() - start
        @total = results.total
        @max_score = results.max_score
        @reset(results.hits)

  # Remove my various bits of state.
  clear: ->
    @reset()
    @searchtime = null
    @max_score = null
    @total = null
    @query_str = null
