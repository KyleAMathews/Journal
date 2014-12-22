Reflux = require 'reflux'
PostActions = require '../actions/PostActions'

module.exports = PostStore = Reflux.createStore
  listenables: PostActions

  getInitialState: ->
    false

  onLoad: ->
    @trigger true

  onLoadComplete: ->
    @trigger false

  onLoadError: ->
    @trigger false

  onLoadMore: ->
    @trigger true

  onLoadMoreComplete: ->
    @trigger false

  onLoadMoreError: ->
    @trigger false
