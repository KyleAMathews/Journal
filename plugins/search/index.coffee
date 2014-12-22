Joi = require 'joi'
elasticsearch = require 'elasticsearch'
_ = require 'underscore'
Boom = require 'boom'

client = new elasticsearch.Client({
  host: process.env.ELASTICSEARCH_URL
  #log: 'trace'
})

exports.register = (server, options, next) ->
  server.route
    path: "/search"
    method: "GET"
    config:
      validate:
        query:
          q: Joi.string()
          size: Joi.number().min(10).max(100).default(30)
          start: Joi.number().min(0).default(0)
          sort: Joi.any()
      handler: (request, reply) ->
        query = {
          index: 'journal_posts'
          body:
            size: request.query.size
            from: request.query.start
            query:
              query_string:
                fields: ['title', 'body'] # search the title and body of posts.
                default_operator: 'AND'   # require all query terms to match
                query: request.query.q    # The query from the REST call.
                use_dis_max: true
                fuzzy_prefix_length : 3
            filter:
              term:
                deleted: false
                draft: false
            facets:
              month:
                date_histogram:
                  field: 'created'
                  interval: 'hour'
            highlight:
              fields:
                title: {"fragment_size" : 300}
                body: {"fragment_size" : 200}
          }

        if request.query.sort isnt ""
          query.body = _.extend query.body, sort: created: order: request.query.sort

        client.search(query).then (body) ->
          reply body

  next()

exports.register.attributes =
  name: 'searchAPI'
  version: '1.0.0'
