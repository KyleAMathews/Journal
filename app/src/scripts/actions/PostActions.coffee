Reflux = require 'reflux'
API = require '../utils/API'

PostActions = module.exports = Reflux.createActions([
  'load'
  'loadComplete'
  'loadError'
  'loadMore'
  'loadMoreComplete'
  'loadMoreError'
  'create'
  'createComplete'
  'createError'
  'update'
  'updateComplete'
  'updateError'
  'delete'
  'deleteComplete'
  'deleteError'
])

PostActions.load.preEmit = ->
  API.postsLoad()
    .then(PostActions.loadComplete)
    .catch(PostActions.loadError)

PostActions.loadMore.preEmit = (lastPost) ->
  API.postsLoadMore(lastPost.created_at)
    .then(PostActions.loadMoreComplete)
    .catch(PostActions.loadMoreError)

PostActions.create.preEmit = (post) ->
  API.postsCreate(post)
    .then(PostActions.createComplete)
    .catch(PostActions.createError)

PostActions.update.preEmit = (post) ->
  API.postsUpdate(post)
    .then(PostActions.updateComplete)
    .catch(PostActions.updateError)

PostActions.delete.preEmit = (post) ->
  API.postsDelete(post)
    .then(PostActions.deleteComplete)
    .catch(PostActions.deleteError)
