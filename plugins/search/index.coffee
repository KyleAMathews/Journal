Joi = require 'joi'
elasticsearch = require 'elasticsearch'
_ = require 'underscore'
es = require('event-stream')
Boom = require 'boom'
async = require 'async'
lunr = require 'lunr'
posts = {}
index = lunr ->
  @field('title', boost: 10)
  @field('body')

exports.register = (server, options, next) ->
  # Index posts.
  db = server.plugins.dbs.postsDb
  wrappedDb = server.plugins.dbs.wrappedDb
  db.createReadStream()
    .on 'data', (data) ->
      posts[data.value.id] = data.value
      index.add(data.value)
    .on 'end', ->
      console.log "Indexing done"

  server.route
    path: "/search"
    method: "GET"
    config:
      validate:
        query:
          q: Joi.string().required()
          size: Joi.number().min(1).max(100).default(30)
          start: Joi.number().min(0).default(0)
          sort: Joi.valid(["", "asc", "desc"])
      handler: (request, reply) ->
        # TODO create posts store with add/destroy/update + search
        # that the search can use.
        start = process.hrtime()

        # Perform search.
        hits = index.search request.query.q

        total = hits.length

        # Hydrate
        hits = hits.map (result) -> posts[result.ref]

        # Sort

        # Oldest first
        if request.query.sort is "asc"
          hits = _.sortBy hits, (hit) -> hit.created_at

        # Newest first
        else if request.query.sort is "desc"
          hits = _.sortBy hits, (hit) -> hit.created_at
          hits.reverse()

        # Slice.
        hits = hits.slice(request.query.start, request.query.size)

        reply {
          total: total
          hits: hits
          offset: request.query.start
          took: process.hrtime(start)[1] / 1000000
        }

  next()

exports.register.attributes =
  name: 'searchAPI'
  version: '1.0.0'
