Joi = require 'joi'
levelQuery = require('level-queryengine')
pathEngine = require('path-engine')
levelup = require 'levelup'
es = require('event-stream')
_ = require 'underscore'
async = require 'async'
memwatch = require('memwatch')
memwatch.on 'lead', (info) -> console.log info
memwatch.on 'stats', (info) ->
  console.log info
  console.log info.current_base / 1024 / 1024 + " MB"

db = levelup('./postsdb', valueEncoding: 'json')
postsDb = levelQuery(db)
postsDb.query.use(pathEngine())
postsDb.ensureIndex('id')
postsDb.ensureIndex('updated_at')

exports.register = (plugin, options, next) ->
  #########################################################
  ### GET /posts
  #########################################################
  plugin.route
    path: "/posts"
    method: "GET"
    config:
      validate:
        query:
          limit: Joi.number().integer().max(5000).default(10)
          updated_since: Joi.string()
          start: Joi.string().default(new Date().toJSON())
          until: Joi.string()
      handler: (request, reply) ->
        # User is querying for all posts changed since a certain date.
        if request.query.updated_since?
          ids = []
          postsDb.indexes['updated_at'].createIndexStream(
              start: request.query.updated_since
              end: request.query.until
            )
            .on 'data', (data) ->
              ids.push data.value
            .on 'end', ->
              async.map ids, ((id, cb) -> postsDb.get(id, cb)), (err, results) ->
                reply results.reverse()

        else
          db.createValueStream(
            reverse: true
            limit: request.query.limit
            start: request.query.start
          ).pipe(es.writeArray (err, array) ->
            reply array
          )

  #########################################################
  ### GET /posts/{id}
  #########################################################

  postOptions =
  plugin.route
    path: "/posts/{id}"
    method: "GET"
    config:
      validate:
        params:
          id: Joi.number().integer().max(999999).min(1).required()
      handler: (request, reply) ->
        postsDb.query(['id', request.params.id]).pipe(es.writeArray (err, array) ->
          reply array[0]
        )

  #########################################################
  ### PATCH /posts/{id}
  #########################################################

  plugin.route
    path: "/posts/{id}"
    method: "PATCH"
    config:
      validate:
        params:
          id: Joi.number().integer().max(999999).min(1).required()
      handler: (request, reply) ->
        postsDb.query(['id', request.params.id]).pipe(es.writeArray (err, array) ->
          # Override, make changes, reply with new setup.
          reply array[0]
        )

  #########################################################
  ### POST /posts/
  #########################################################

  plugin.route
    path: "/posts/"
    method: "POST"
    config:
      handler: (request, reply) ->
        # Create new post and return
        reply()

  next()

exports.register.attributes =
  name: 'postsAPI'
  version: '1.0.0'

