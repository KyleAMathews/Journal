Dispatcher = require '../dispatcher'
SearchConstants = require '../constants/search_constants'
request = require 'superagent'
_ = require 'underscore'
log = require('bows')("SearchTransport")
moment = require 'moment'

_loading = {}

search = (query, sort) ->
  # Don't double-load.
  if "#{query}#{sort}" of _loading then return

  _loading["#{query}#{sort}"] = true

  log "Searching for query: '#{query}' by sort: '#{sort}'"
  searchStart = new Date()
  request
    .get('http://localhost:8081/search')
    .set('Accept', 'application/json')
    .query(q: query)
    .query(size: 30)
    .query(sort: sort)
    .end (err, res) ->
      delete _loading["#{query}#{sort}"]
      if res?.status is 200
        Dispatcher.emit SearchConstants.SEARCH_COMPLETE,
          body: res.body
          took: new Date() - searchStart
          errors: []
          query: query
          sort: sort
          start: 0
      else
        error = ""
        if err?.message
          error = err.message
        else
          error = "#{res.body.statusCode} #{res.body.error}: #{res.body.message}"

        Dispatcher.emit SearchConstants.SEARCH_ERROR, {
          error: error
          query: query
          sort: sort
        }

# Register to dispatcher.
Dispatcher.on '*', (action, args...) ->
  switch action
    when SearchConstants.SEARCH
      search(args[0], args[1])
