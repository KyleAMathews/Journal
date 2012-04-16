{Post} = require 'models/post'
class exports.Posts extends Backbone.Collection

  url: '/posts'
  model: Post

  getByNid: (nid) ->
    nid = parseInt(nid, 10)
    return @find (post) -> post.get('nid') is nid
