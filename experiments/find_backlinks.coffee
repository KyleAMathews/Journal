_ = require 'underscore'
config = require '../app_config'
MongoClient = require('mongodb').MongoClient
MongoClient.connect(config.mongo_url, (err, db) ->
  collection = db.collection('posts')
  collection.find().toArray((err, results) ->
    backlinks = []
    nodes = {}
    pattern = /\[.+?\]\(\/?node\/(\d+)\)/g
    for post in results
      nodes[post.nid] = post.title
      match = []
      while (match = pattern.exec(post.body))
        backlinks.push match[1]

    for link, count of _.groupBy backlinks
      console.log count.length, nodes[link]

    db.close()
  )
)
