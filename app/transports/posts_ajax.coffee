Dispatcher = require '../dispatcher'
PostConstants = require '../constants/post_constants'
request = require 'superagent'
_ = require 'underscore'
log = require('bows')("PostTransport")
moment = require 'moment'

_start = new Date().toJSON()
_fetchedAll = false
_postsLoading = {}

fetchPosts = ->
  # We've fetched all posts, nothing to do here.
  if _fetchedAll then return
  log 'GET /posts'
  request
    .get('/posts')
    .set('Accept', 'application/json')
    .query(limit: 50)
    .query(start: _start)
    .end (err, res) =>
      if res.status is 200
        if res.body.length is 0
          _fetchedAll = true
        else
          _start = moment(_.last(res.body).created_at).subtract('seconds', 1).toJSON()
          Dispatcher.emit PostConstants.POSTS_ADD, res.body
      else
        if err?.message
          error = err.message
        else
          error = createErrorMessage(res.body)
        Dispatcher.emit PostConstants.POSTS_FETCH_ERROR, {
          status: res.status
          error: error
        }

fetchPost = (id) ->
  log "GET /posts/#{id}"
  # Don't double-load
  if id of _postsLoading then return

  _postsLoading[id] = true

  # Make request.
  request
    .get("/posts/#{id}")
    .set('Accept', 'application/json')
    .end (err, res) =>
      delete _postsLoading[id]

      if res.status is 200
        Dispatcher.emit PostConstants.POSTS_ADD, [res.body]
      else
        if err?.message
          error = err.message
        else
          error = createErrorMessage(res.body)
        Dispatcher.emit PostConstants.POST_FETCH_ERROR,
          {id: id, status: res.status, error: error}

createPost = (post) ->
  log "POST /posts", post
  request
    .post("/posts")
    .set('Accept', 'application/json')
    .send(post)
    .end (err, res) =>
      if res?.status is 201
        Dispatcher.emit PostConstants.POST_CREATE_COMPLETE, res.body
      else
        if err?.message
          error = err.message
        else
          error = createErrorMessage(res.body)
        Dispatcher.emit PostConstants.POST_CREATE_ERROR,
          post: post
          status: res?.status
          error: error

updatePost = (post) ->
  log "PATCH /posts/id", post
  request
    .patch("/posts/#{post.id}")
    .set('Accept', 'application/json')
    .send(post)
    .end (err, res) =>
      if res?.status is 200
        Dispatcher.emit PostConstants.POST_UPDATE_COMPLETE, res.body
      else
        if err?.message
          error = err.message
        else
          error = createErrorMessage(res.body)
        Dispatcher.emit PostConstants.POST_UPDATE_ERROR,
          post: post
          status: res?.status
          error: error

# Register to dispatcher.
Dispatcher.on '*', (action, args...) ->
  switch action
    when PostConstants.POSTS_FETCH
      fetchPosts()
    when PostConstants.POST_FETCH
      fetchPost(args[0])
    when PostConstants.POST_CREATE
      createPost(args[0])
    when PostConstants.POST_UPDATE
      updatePost(args[0])

createErrorMessage = (body) ->
  return "#{body.statusCode} #{body.error}: #{body.message}"
