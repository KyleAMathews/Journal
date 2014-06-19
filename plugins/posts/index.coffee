Joi = require 'joi'
levelup = require 'levelup'
es = require('event-stream')

postsDb = levelup './postsdb', valueEncoding: 'json'

createKey = (id) ->
  "post-#{id}"

pad = (int) ->
  pading = "000000"
  id = pading.substring(0, pading.length - String(int).length) + int

exports.register = (plugin, options, next) ->
  postsOptions =
    validate:
      query:
        limit: Joi.number().integer().max(5000).default(10)
        start: Joi.number().integer().min(1).default(999999)
    handler: (request, reply) ->
      start = createKey(pad(request.query.start))
      postsDb.createValueStream(
        reverse: true
        limit: request.query.limit
        start: start
      ).pipe(es.writeArray (err, array) ->
        reply array
      )

  plugin.route
    path: "/posts"
    method: "GET"
    config: postsOptions

  next()

exports.register.attributes =
  name: 'postsAPI'
  version: '1.0.0'

