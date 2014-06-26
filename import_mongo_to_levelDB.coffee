REMOTE_ADDRESS = "69.164.194.245:"
MongoClient = require('mongodb').MongoClient
levelup = require 'levelup'
postsDb = levelup './postsdb', valueEncoding: 'json'
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
      delete post._id
      delete post._user
      post.id = post.nid
      delete post.nid
      console.log post
      postsDb.put createKey(pad(post.id)), post
)
