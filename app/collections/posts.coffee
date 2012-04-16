{Post} = require 'models/post'
class exports.Posts extends Backbone.Collection

  url: '/posts'
  model: Post
