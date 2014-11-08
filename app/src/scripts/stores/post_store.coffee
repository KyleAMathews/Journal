Reflux = require 'reflux'
PostActions = require '../actions/PostActions'
Immutable = require 'immutable'

module.exports = PostStore = Reflux.createStore
  init: ->
    @_posts = null
    @_mappedPosts = Immutable.Map({})
    @listenTo PostActions.loadComplete, @onLoad
    @listenTo PostActions.loadMoreComplete, @onLoadMore

  getDefaultData: ->
    @_posts

  get: (id) ->
    id = parseInt(id, 10)
    @_mappedPosts.get(id)

  onLoad: (posts) ->
    @_posts = Immutable.List(posts.body)
    @_posts = @sort(@_posts)
    @addToMap(@_posts)
    @trigger(@_posts)

  onLoadMore: (newPosts) ->
    @addToMap(newPosts.body)
    @_posts = @_posts.concat newPosts.body
    @_posts = @sort(@_posts)
    @trigger(@_posts)

  sort: (posts) ->
    posts.sortBy(
      ((post) -> post.created_at),
      ((a, b) -> a - b)
    )

  addToMap: (posts) ->
    posts.forEach (post) =>
      @_mappedPosts = @_mappedPosts.set(post.id, post)
