_ = require 'underscore'

exports.register = (server, options, next) ->

  eventsDb = server.plugins.dbs.eventsDb
  postsByIdDb = server.plugins.dbs.postsByIdDb
  postsByLastUpdatedDb = server.plugins.dbs.postsByLastUpdatedDb

  a =
    posts: {}

  eventsDb.createReadStream()
    .on('data', (data) ->
      #console.log data
      [key, timestamp, event] = data.key.split("__")
      #console.log key, event
      if event is "postCreated"
        a.posts[key] = data.value
      else if event is "postUpdated"
        #console.log "updated", data
        a.posts[key] = _.extend a.posts[key], data.value
      else if event is "postDeleted"
        delete a.posts[key]
    )
    .on('end', ->
      # Update id + updated_at indexes.
      for k,v of a.posts
        postsByIdDb.put k, v
        postsByLastUpdatedDb.put "#{v.updated_at}-#{k}", v

      delete a.posts
    )

  next()

exports.register.attributes =
  name: 'create_snapshots'
  version: '1.0.0'

