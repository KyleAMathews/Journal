Joi = require 'joi'
es = require('event-stream')
_ = require 'underscore'
async = require 'async'

config = require '../../config'

# If there's no posts (e.g. fresh install of the application) add a sample one.
config.db.createKeyStream().pipe(es.writeArray (err, array) ->
  if array.length is 0
    post =
      title: "Welcome to your new Journal!"
      body: "This is a sample post. Try editing this post to see how things work.
        You can use **Markdown** to format your posts.\n\nIf you find bugs
        or otherwise need help, [post at an issue on Github](https://github.com/KyleAMathews/Journal/issues?state=open)."
      created_at: new Date().toJSON()
      updated_at: new Date().toJSON()
      id: 1
      deleted: false
      starred: false
    config.wrappedDb.put post.created_at, post
)

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
          updated_since: Joi.date()
          start: Joi.date().default(new Date().toJSON())
          until: Joi.date()
      handler: (request, reply) ->
        # User is querying for all posts changed since a certain date.
        if request.query.updated_since?
          ids = []
          config.wrappedDb.indexes['updated_at'].createIndexStream(
              start: request.query.updated_since.toJSON()
              end: request.query.until.toJSON()
            )
            .on 'data', (data) ->
              unless data.value.deleted
                ids.push data.value
            .on 'end', ->
              async.map ids, ((id, cb) -> config.wrappedDb.get(id, cb)), (err, results) ->
                reply results.reverse()

        else
          config.db.createValueStream(
            reverse: true
            limit: request.query.limit
            start: request.query.start.toJSON()
          ).pipe(es.writeArray (err, array) ->
            reply array.filter (post) -> not post.deleted
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
        config.wrappedDb.query(['id', request.params.id]).pipe(es.writeArray (err, array) ->
          if array.length is 0
            reply(plugin.hapi.error.notFound('Post not found'))
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
        payload:
          id: Joi.number().required().min(1).max(999999)
          title: Joi.string().min(1)
          body: Joi.string().min(1)
          created_at: Joi.any()
          updated_at: Joi.any()
          deleted: Joi.boolean()
          starred: Joi.boolean()
          latitude: Joi.any()
          longitude: Joi.any()
      handler: (request, reply) ->
        config.wrappedDb.query(['id', request.params.id]).pipe(es.writeArray (err, array) ->
          if array.length is 0
            reply(plugin.hapi.error.notFound('Post not found'))
          # Change updated_at
          post = _.extend array[0], request.payload, updated_at: new Date().toJSON()
          # Save
          config.db.put(post.created_at, post, (err) ->
            if err
              reply plugin.hapi.error.internal {
                err: err
                message: "Post update didn't save correctly: #{ JSON.stringify(err) }"
              }
            reply post

            # Enqueue updated post to be pushed to S3
            config.jobsClient.push jobName: 'push_post_s3', post: post
          )
        )

  #########################################################
  ### POST /posts/
  #########################################################

  plugin.route
    path: "/posts"
    method: "POST"
    config:
      validate:
        payload:
          id: Joi.string().required()
          title: Joi.string().min(1)
          body: Joi.string().min(1)
          created_at: Joi.any().required()
          deleted: Joi.boolean().default(false)
          starred: Joi.boolean().default(false)
          latitude: Joi.number().min(0).max(90)
          longitude: Joi.number().min(-180).max(180)

      handler: (request, reply) ->
        # Create new post and return
        newPost = request.payload
        newPost.updated_at = new Date().toJSON()
        temp_id = newPost.id

        config.db.createValueStream()
          .pipe(es.writeArray (err, array) ->
            max = _.max(array, (post) -> post.id).id
            if max?
              newId = max + 1
            else
              newId = 1
            newPost.id = newId

            # Save
            config.wrappedDb.put(newPost.created_at, newPost, (err) ->
              # Add back temp_id to newPost
              newPost.temp_id = temp_id
              response = reply(newPost)
              response.created("/posts/#{newPost.id}")

              # Enqueue updated post to be pushed to S3
              postNoTempId = _.extend({}, newPost)
              delete postNoTempId.temp_id
              config.jobsClient.push jobName: 'push_post_s3', post: postNoTempId
            )
          )

  #########################################################
  ### DELETE /posts/{id}
  #########################################################

  plugin.route
    path: "/posts/{id}"
    method: "DELETE"
    config:
      validate:
        params:
          id: Joi.number().integer().max(999999).min(1).required()
      handler: (request, reply) ->
        config.wrappedDb.query(['id', request.params.id]).pipe(es.writeArray (err, array) ->
          if array.length is 0
            reply(plugin.hapi.error.notFound('Post not found'))
          # Change updated_at
          post = _.extend array[0], deleted: true, updated_at: new Date().toJSON()
          # Save
          config.db.put(post.created_at, post, (err) ->
            if err
              reply plugin.hapi.error.internal {
                err: err
                message: "Post update wasn't deleted correctly: #{ JSON.stringify(err) }"
              }
            reply post

            # Enqueue updated post to be pushed to S3
            config.jobsClient.push jobName: 'push_post_s3', post: post
          )
        )
  next()

exports.register.attributes =
  name: 'postsAPI'
  version: '1.0.0'

