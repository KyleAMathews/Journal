Reflux = require 'reflux'
API = require '../utils/API'

PostActions = module.exports = Reflux.createActions([
  'load'
  'loadComplete'
  'loadError'
  'loadMore'
  'loadMoreComplete'
  'loadMoreError'
])

PostActions.load.preEmit = ->
  API.postsLoad()
    .then(PostActions.loadComplete)
    .catch(PostActions.loadError)

PostActions.loadMore.preEmit = (lastPost) ->
  API.postsLoadMore(lastPost.created_at)
    .then(PostActions.loadMoreComplete)
    .catch(PostActions.loadMoreError)
