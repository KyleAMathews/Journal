Reflux = require 'reflux'
PostActions = require '../actions/PostActions'
Immutable = require 'immutable'
request = require 'superagent'
Promise = require 'bluebird'

module.exports = DraftStore = Reflux.createStore
  init: ->
    @_posts = null
    @_mappedPosts = Immutable.Map({})
    @listenTo PostActions.loadComplete, @onLoad
    @listenTo PostActions.loadMoreComplete, @onLoadMore

  getInitialState: ->
    @_posts

  get: (id) ->
    id = parseInt(id, 10)
    post = @_mappedPosts.get(id)
    if post?
      return new Promise (resolve, reject) ->
        resolve post
    else
      request
        .get("http://localhost:8081/posts/#{id}")
        .set('Accept', 'application/json')
        .promise()
        .then (res) ->
          res.body

  onLoad: (res) ->
    posts = _.filter res.body, (post) -> post.draft is true
    @_posts = Immutable.List(posts)
    @_posts = @sort(@_posts)
    @addToMap(@_posts)
    @trigger(@_posts)

  onLoadMore: (res) ->
    posts = _.filter res.body, (post) -> post.draft is true
    @addToMap(posts)
    @_posts = @_posts.concat posts
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

