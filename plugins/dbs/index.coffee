knoxCopy = require 'knox-copy'
levelup = require 'level'
#QueueClient = require('level-jobs/client')
config = require 'config'
lunr = require 'lunr'
_ = require 'underscore'

posts = {}
index = lunr ->
  @field('title', boost: 10)
  @field('body')

exports.register = (server, options, next) ->

  DBS_DIRECTORY = config.get('db.directory')
  postsByIdDb = levelup(DBS_DIRECTORY + '/posts_by_id', valueEncoding: 'json')
  postsByLastUpdatedDb = levelup(DBS_DIRECTORY + '/posts_last_updated', valueEncoding: 'json')
  postsByCreatedDB = levelup(DBS_DIRECTORY + '/posts_by_created', valueEncoding: 'json')
  eventsDb = levelup(DBS_DIRECTORY + '/events_db', valueEncoding: 'json')

  syncPosts = ->
    console.log "Adding posts to search index."
    postsByIdDb.createReadStream()
      .on 'data', (data) ->
        index.add(data.value)
      .on 'end', ->
        console.log "Done adding posts to search index."

  syncPosts()
  server.expose('syncPosts', syncPosts)

  server.expose('postsByIdDb', postsByIdDb)
  server.expose('postsByLastUpdatedDb', postsByLastUpdatedDb)
  server.expose('postsByCreatedDB', postsByCreatedDB)
  server.expose('eventsDb', eventsDb)
  server.expose('index', index)

  next()

exports.register.attributes =
  name: 'dbs'
  version: '1.0.0'
