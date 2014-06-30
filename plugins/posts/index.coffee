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

postsDb = levelQuery levelup './postsdb', valueEncoding: 'json'
postsDb.query.use(pathEngine())
postsDb.ensureIndex('id')
postsDb.ensureIndex('changed')

exports.register = (plugin, options, next) ->
  postsOptions =
    validate:
      query:
        limit: Joi.number().integer().max(5000).default(10)
        changed_since: Joi.string()
        start: Joi.string().default(new Date().toJSON())
    handler: (request, reply) ->
      # User is querying for all posts changed since a certain date.
      if request.query.changed_since?
        ids = []
        postsDb.indexes['changed'].createIndexStream(start:request.query.changed_since)
          .on 'data', (data) ->
            ids.push data.value
          .on 'end', ->
            async.map ids, ((id, cb) -> postsDb.get(id, cb)), (err, results) ->
              reply results

      else
        postsDb.createValueStream(
          reverse: true
          limit: request.query.limit
          start: request.query.start
        ).pipe(es.writeArray (err, array) ->
          reply array
        )
  plugin.route
    path: "/posts"
    method: "GET"
    config: postsOptions

  postOptions =
    validate:
      params:
        id: Joi.number().integer().max(999999).min(1).required()
    handler: (request, reply) ->
      postsDb.query(['id', request.params.id]).pipe(es.writeArray (err, array) ->
        reply array[0]
      )
  plugin.route
    path: "/posts/{id}"
    method: "GET"
    config: postOptions

  next()

exports.register.attributes =
  name: 'postsAPI'
  version: '1.0.0'

