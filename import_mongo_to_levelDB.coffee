MongoClient = require('mongodb').MongoClient
levelup = require 'level'
eventsDb = levelup './journal/events_db', valueEncoding: 'json'
moment = require 'moment'
_ = require 'underscore'
path = require 'path'
fs = require 'fs'

createKey = (id) ->
  "post-#{id}"

pad = (int) ->
  pading = "000000"
  id = pading.substring(0, pading.length - String(int).length) + int

picMap = JSON.parse fs.readFileSync('./pic_map.json')
#console.log picMap

MongoClient.connect("mongodb://#{process.env.REMOTE_ADDRESS}:27017/journal", (err, db) ->
  collection = db.collection('posts')
  collection.count (err, count) ->
    console.log count
  collection.find().toArray (err, results) ->
    for post in results
      #console.log post._user
      #console.log post
      delete post._id
      delete post._user
      post.id = post.nid
      delete post.nid
      post.created_at = moment(post.created).toJSON()
      post.updated_at = moment(post.changed).toJSON()
      delete post.created
      delete post.changed
      delete post.draft

      # Replace http://localhost.*node/#### links
      re = new RegExp(/http:\/\/.*(node)(\/\d+)/g)
      post.body = post.body.replace(re, "/posts$2")

      # Replace (/journal/node/####)
      re = new RegExp(/\(\/journal\/node\/(\d+)\)/g)
      post.body = post.body.replace(re, "(/posts/$1)")

      # Replace /node/#### links w/ /post/####
      re = new RegExp(/node(\/\d+\))/g)
      post.body = post.body.replace(re, "/posts$1")

      # Replace standalone /node/####
      re = new RegExp(/\/?node\/(\d+)/g)
      post.body = post.body.replace(re, "/posts/$1")

      re = new RegExp(/\!\[.*\]\((.*)\)/g)
      keyRe = new RegExp(/\(\/attachments\/(.*)\)/i)
      match = post.body.match(re)
      if match
        for pic in match
          attachmentKey = keyRe.exec(pic)[1]
          newUrl = "https://kyle-journal.s3-us-west-1.amazonaws.com/pictures/#{picMap[attachmentKey]}"
          picRe = new RegExp("/attachments/#{attachmentKey}", 'img')
          post.body = post.body.replace(picRe, newUrl)

      eventsDb.put "#{post.id}__#{post.created_at}__postCreated", post
      console.log "PUT #{post.id}"
)
