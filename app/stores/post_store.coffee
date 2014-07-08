Dispatcher = require '../dispatcher'
PostConstants = require '../constants/post_constants'
Emitter = require('wildemitter')

CHANGE_EVENT = "change"
ADD_EVENT = "add"
CHANGE_ERROR_EVENT = "change_error"

_posts = {}
_errors = {}

# Posts internal API
create = (post) ->
  _posts[post.id] = post

update = (post) ->
  _posts[post.id] = post

destroy = (post) ->
  delete _posts[post.id]

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
    return _posts

  get: (id) ->
    id = parseInt(id, 10)
    post = _.find _posts, (post) -> return post.id is id
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
