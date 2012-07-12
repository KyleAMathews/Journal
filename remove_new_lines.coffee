mongoose = require 'mongoose'
require './post_schema'
Post = mongoose.model 'post'
Post.find()
  .run (err, posts) ->
    for post in posts
      post.body = post.get('body').replace(/([^\n]+)(\n)/g, "$1 ").replace(/\n/g, "\n\n").replace(/\s\n\n/gi, "\n\n")
      post.save()
