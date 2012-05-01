{Post} = require 'models/post'
class exports.Posts extends Backbone.Collection

  url: '/posts'
  model: Post

  getByNid: (nid) ->
    nid = parseInt(nid, 10)
    return @find (post) -> post.get('nid') is nid

   comparator: (model, model2) ->
     if model.get('created') is model2.get('created') then return 0
     if model.get('created') < model2.get('created') then return 1 else return -1
