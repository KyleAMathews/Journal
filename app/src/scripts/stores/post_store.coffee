Reflux = require 'reflux'
PostActions = require '../actions/PostActions'

module.exports = PostStore = Reflux.createStore({
  init: ->
    @_posts = []
    @listenTo PostActions.loadComplete, @onLoad

  getDefaultData: ->
    @_posts

  get: (id) ->
    _.find @_posts, (post) -> post.id is parseInt(id, 10)

  onLoad: (posts) ->
    @_posts = posts.body
    @trigger(@_posts)
})
