Dispatcher = require '../dispatcher'
PostConstants = require '../constants/post_constants'
Emitter = require('wildemitter')

CHANGE_EVENT = "change"
ADD_EVENT = "add"

_posts = {}

create = (post) ->
  _posts[post.id] = post

update = (post) ->
  _posts[post.id] = post

destroy = (post) ->
  delete _posts[post.id]

class PostsStore extends Emitter
  getAll: ->
    return _posts

  get: (id) ->
    id = parseInt(id, 10)
    post = _.find _posts, (post) -> return post.id is id
    unless post?
      Dispatcher.emit PostConstants.POST_FETCH, id

    return post

  emitChange: ->
    @emit CHANGE_EVENT

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
