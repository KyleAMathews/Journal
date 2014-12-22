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

  postsUpdate: (post) ->
    log "PATCH /posts/#{post.id}"
    request
      .patch("http://localhost:8081/posts/#{post.id}")
      .set('Accept', 'application/json')
      .send(post)
      .promise()

  postsDelete: (post) ->
    log "DELETE /posts/#{post.id}"
    request
      .del("/posts/#{post.id}")
      .set('Accept', 'application/json')
      .promise()
