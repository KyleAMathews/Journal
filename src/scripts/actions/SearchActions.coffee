Reflux = require 'reflux'
API = require '../utils/API'
request = require 'superagent-bluebird-promise'

SearchActions = module.exports = Reflux.createActions([
  'search'
  'searchComplete'
  'searchError'
  'updateQuery'
])

SearchActions.search.listen (query, sort) ->
  request
    .get("http://127.0.0.1:8081/search")
    .set('Accept', 'application/json')
    .query(q: query)
    .query(sort: sort)
    .promise()
    .then (res) ->
      SearchActions.searchComplete {
        loading: false
        hits: res.body.hits
        took: res.body.took
        total: res.body.total
        query: query
        sort: sort
      }
    .catch (res) ->
      SearchActions.searchError(res)
