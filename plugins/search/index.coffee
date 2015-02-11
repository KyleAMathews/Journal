Joi = require 'joi'
elasticsearch = require 'elasticsearch'
_ = require 'underscore'
es = require('event-stream')
Boom = require 'boom'
async = require 'async'

exports.register = (server, options, next) ->
  # Index posts.
  db = server.plugins.dbs.postsDb
  posts = server.plugins.dbs.posts
  index = server.plugins.dbs.index

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
