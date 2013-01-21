module.exports = class PostsCache extends Backbone.Collection

  getByNid: (nid) ->
    nid = parseInt(nid, 10)
    return @find (post) -> post.get('nid') is nid
