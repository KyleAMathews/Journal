Reflux = require 'reflux'
SearchActions = require '../actions/SearchActions'
Immutable = require 'immutable'
request = require 'superagent'
Promise = require 'bluebird'

module.exports = PostStore = Reflux.createStore

  listenables: SearchActions

  init: ->
    @_search = {
      hits: []
      took: 0
      total: 0
    }

  getInitialState: ->
    @_search

  onSearch: (query, sort) ->
    @_search.sort = sort
    @trigger @_search

  onSearchComplete: (search) ->
    @_search = search
    @trigger @_search

  onUpdateQuery: (newQuery) ->
    @_search.query = newQuery
    @trigger @_search
