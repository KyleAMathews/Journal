mongoose = require 'mongoose'
require './post_schema'
Post = mongoose.model 'post'
Post.find()
  .where('created').lt("2012-04-14T19:00:00.000Z")
  .desc('created')
  .run (err, posts) ->
    for post in posts
      post.body = post.get('body').replace(/([^\n]+)(\n)/g, "$1 ").replace(/\n/g, "\n\n").replace(/\s\n\n/gi, "\n\n")
      post.save()
