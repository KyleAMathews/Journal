request = require 'superagent'
require 'superagent-bluebird-promise'
log = require('bows')("PostTransport")

module.exports =
  postsLoad: ->
    log 'GET /posts'
    request
      .get('http://localhost:8081/posts')
      .set('Accept', 'application/json')
      .query(limit: 50)
      .query(start: new Date().toJSON())
      .promise()

  postsLoadMore: (startDate) ->
    log 'GET /posts'
    request
      .get('http://localhost:8081/posts')
      .set('Accept', 'application/json')
      .query(limit: 50)
      .query(start: startDate)
      .promise()
