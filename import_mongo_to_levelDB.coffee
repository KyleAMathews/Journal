REMOTE_ADDRESS = "69.164.194.245:"
MongoClient = require('mongodb').MongoClient
levelup = require 'levelup'
postsDb = levelup './postsdb', valueEncoding: 'json'
moment = require 'moment'
_ = require 'underscore'

createKey = (id) ->
  "post-#{id}"

pad = (int) ->
  pading = "000000"
  id = pading.substring(0, pading.length - String(int).length) + int

MongoClient.connect('mongodb://69.164.194.245:27017/journal', (err, db) ->
  collection = db.collection('posts')
  collection.count (err, count) ->
    console.log count
  collection.find().toArray (err, results) ->
    for post in results
      console.log post._user
      console.log post
      delete post._id
      delete post._user
      post.id = post.nid
      delete post.nid
      post.created_at = moment(post.created).toJSON()
      post.updated_at = moment(post.changed).toJSON()
      delete post.created
      delete post.changed
      console.log post
      postsDb.put post.created_at, post
)
