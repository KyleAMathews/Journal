Reflux = require 'reflux'
PostActions = require '../actions/PostActions'
Immutable = require 'immutable'

module.exports = PostStore = Reflux.createStore
  init: ->
    @_posts = null
    @_mappedPosts = Immutable.Map({})
    @listenTo PostActions.loadComplete, @onLoad

  getDefaultData: ->
    @_posts

  get: (id) ->
    id = parseInt(id, 10)
    @_mappedPosts.get(id)

  onLoad: (posts) ->
    @_posts = Immutable.List(posts.body)
    @_posts = @sort()
    @addToMap(@_posts)
    @trigger(@_posts)

  sort: ->
    @_posts.sortBy(
      ((post) -> post.created_at),
      ((a, b) -> a - b)
    )

  addToMap: (posts) ->
    posts.forEach (post) =>
      @_mappedPosts = @_mappedPosts.set(post.id, post)
