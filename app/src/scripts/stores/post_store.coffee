Dispatcher = require '../dispatcher'
PostConstants = require '../constants/post_constants'
Emitter = require('wildemitter')
mori = require 'mori'

CHANGE_EVENT = "change"
ADD_EVENT = "add"
CHANGE_ERROR_EVENT = "change_error"

_posts = {}
_errors = {}

_posts_sorted = mori.sorted_set_by((a, b) ->
  return a.created_at > b.created_at
)

# Posts internal API
create = (post) ->
  _posts[post.id] = post
  _posts_sorted = mori.conj(_posts_sorted, post)

update = (post) ->
  _posts[post.id] = post
  _posts_sorted = mori.conj(_posts_sorted, post)

destroy = (post) ->
  delete _posts[post.id]
  _posts_sorted = mori.disj(_posts_sorted, post)

# Errors internal API
createError = (postId, errorType, error) ->
  unless postId of _errors then _errors[postId] = {}
  unless errorType of _errors[postId] then _errors[postId][errorType] = []
  _errors[postId][errorType] = _errors[postId][errorType].concat [error]

destroyError = (postId, errorType) ->
  if errorType?
    delete _errors[postId][errorType]
  else
    delete _errors[postId]

class PostsStore extends Emitter
  getAll: ->
    return mori.clj_to_js(_posts_sorted)

  get: (id) ->
    id = parseInt(id, 10)
    post = _posts[id]
    unless post?
      Dispatcher.emit PostConstants.POST_FETCH, id

    return post

  getAllErrors: ->
    return _errors

  getErrorById: (postId) ->
    return _errors[postId]

  emitChange: ->
    @emit CHANGE_EVENT

  emitErrorChange: ->
    @emit CHANGE_ERROR_EVENT

  emitAdd: (newPost) ->
    @emit ADD_EVENT, newPost

module.exports = window.PostStore = PostStore = new PostsStore()

# Register to dispatcher.
Dispatcher.on '*', (action, args...) ->
  switch action
    when PostConstants.POST_CREATE_COMPLETE
      create(args[0])
      PostStore.emitAdd(args[0])

    when PostConstants.POSTS_ADD
      for post in args[0]
        create(post)
      PostStore.emitChange()

    when PostConstants.POST_DELETE_COMPLETE
      destroy(PostStore.get(args[0]))
      PostStore.emitChange()

    when PostConstants.POST_DELETE_ERROR
      error = args[0]
      createError error.postId, PostConstants.POST_DELETE_ERROR, error
      PostStore.emitErrorChange()

    when PostConstants.POST_UPDATE_COMPLETE
      update(args[0])
      PostStore.emitChange()

    when PostConstants.POST_CREATE_ERROR
      error = args[0]
      createError error.post.id, PostConstants.POST_UPDATE_ERROR, error
      PostStore.emitErrorChange()

    when PostConstants.POST_UPDATE_ERROR
      error = args[0]
      createError error.post.id, PostConstants.POST_UPDATE_ERROR, error
      PostStore.emitErrorChange()

    when PostConstants.POST_FETCH_ERROR
      error = args[0]
      createError error.id, PostConstants.POST_FETCH_ERROR, error
      PostStore.emitErrorChange()

    when PostConstants.POSTS_FETCH_ERROR
      error = args[0]
      createError "posts_index", PostConstants.POSTS_FETCH_ERROR, error
      PostStore.emitErrorChange()

    when PostConstants.POST_ERROR_DESTROY
      destroyError args[0], args[1]
