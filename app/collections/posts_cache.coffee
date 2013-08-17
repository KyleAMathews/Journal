Post = require 'models/post'

module.exports = class PostsCache extends Backbone.Collection

  getByNid: (nid) ->
    nid = parseInt(nid, 10)
    if @find((post) -> post.get('nid') is nid)?
      return @find((post) -> post.get('nid') is nid)
    else if app.collections.posts.burry.get(nid)?
      json = app.collections.posts.burry.get(nid)
      post = new Post json

      # Post might have changed since it was stored in the localstorage so resync
      # with the server.
      post.fetch()

      @add post
      return post
    else
      return @fetchPost(nid)

  fetchPost: (pid) ->
    post = new Post( nid: pid, id: null )
    post.fetch( nid: pid )
    @add post
    return post
