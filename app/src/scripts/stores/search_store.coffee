Dispatcher = require '../dispatcher'
SearchConstants = require '../constants/search_constants'
Emitter = require('wildemitter')

CHANGE_EVENT = "change"

_searches = {}

searchSerializeKey = (query, sort) ->
  "search-#{query}-#{sort}"

set = (key, value) ->
  _searches[key] = value

class SearchStore extends Emitter
  getAll: ->
    return _searches

  get: (query, sort) ->
    key = searchSerializeKey(query, sort)
    search = _searches[key]
    unless search?
      Dispatcher.emit SearchConstants.SEARCH, query, sort

    return search

  emitChange: ->
    @emit CHANGE_EVENT

module.exports = SearchStore = new SearchStore()

# Register to dispatcher.
Dispatcher.on '*', (action, args...) ->
  switch action
    when SearchConstants.SEARCH_COMPLETE
      data = args[0]
      result =
        hits: data.body.hits.hits
        facets: data.body.facets.month.entries
        total: data.body.hits.total
        took: data.took
        query: data.query
        sort: data.sort
        start: data.start

      set(searchSerializeKey(result.query, result.sort), result)

      SearchStore.emitChange()

    when SearchConstants.SEARCH_ERROR
      data = args[0]
      set(searchSerializeKey(data.query, data.sort),
        error: true
        message: data.error
      )

      SearchStore.emitChange()
