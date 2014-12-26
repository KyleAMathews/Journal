Joi = require 'joi'
es = require('event-stream')
_ = require 'underscore'
async = require 'async'
Boom = require 'boom'

config = require 'config'

exports.register = (server, options, next) ->
  db = server.plugins.dbs.postsDb
  wrappedDb = server.plugins.dbs.wrappedDb
  jobsClient = server.plugins.dbs.jobsClient

  ## If there's no posts (e.g. fresh install of the application) add a sample one.
  db.createKeyStream().pipe(es.writeArray (err, array) ->
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
      wrappedDb.put post.created_at, post
  )
  #########################################################
  ### GET /posts
  #########################################################
  server.route
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
          wrappedDb.indexes['updated_at'].createIndexStream(
            start: request.query.updated_since.toJSON()
            end: request.query.until.toJSON()
          )
          .on 'data', (data) ->
            unless data.value.deleted
              ids.push data.value
          .on 'end', ->
            async.map ids, ((id, cb) ->
              wrappedDb.get(id, cb)),
              (err, results) ->
                reply results.reverse()

        else
          db.createValueStream(
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
  server.route
    path: "/posts/{id}"
    method: "GET"
    config:
      validate:
        params:
          id: Joi.number().integer().max(999999).min(1).required()
      handler: (request, reply) ->
        wrappedDb.query(['id', request.params.id])
          .pipe(es.writeArray (err, array) ->
            if array.length is 0
              reply(Boom.notFound('Post not found'))
            else
              reply array[0]
        )

  #########################################################
  ### PATCH /posts/{id}
  #########################################################

  server.route
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
        wrappedDb.query(['id', request.params.id])
          .pipe(es.writeArray (err, array) ->
            if array.length is 0
              reply(Boom.notFound('Post not found'))
            else
              # Change updated_at
              post = _.extend(
                array[0],
                request.payload,
                updated_at: new Date().toJSON()
              )

              # Save
              db.put(post.created_at, post, (err) ->
                if err
                  reply Boom.badImplementation(
                    "Post update didn't save correctly",
                    {err: err}
                  )
                else
                  reply post

                # Enqueue updated post to be pushed to S3
                jobsClient.push jobName: 'push_post_s3', post: post
              )
          )

  #########################################################
  ### POST /posts/
  #########################################################

  server.route
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

        db.createValueStream()
          .pipe(es.writeArray (err, array) ->
            max = _.max(array, (post) -> post.id).id
            if max?
              newId = max + 1
            else
              newId = 1
            newPost.id = newId

            # Save
            wrappedDb.put(newPost.created_at, newPost, (err) ->
              # Add back temp_id to newPost
              newPost.temp_id = temp_id
              response = reply(newPost)
              response.created("/posts/#{newPost.id}")

              # Enqueue updated post to be pushed to S3
              postNoTempId = _.extend({}, newPost)
              delete postNoTempId.temp_id
              jobsClient.push jobName: 'push_post_s3', post: postNoTempId
            )
          )

  #########################################################
  ### DELETE /posts/{id}
  #########################################################

  server.route
    path: "/posts/{id}"
    method: "DELETE"
    config:
      validate:
        params:
          id: Joi.number().integer().max(999999).min(1).required()
      handler: (request, reply) ->
        wrappedDb.query(['id', request.params.id])
          .pipe(es.writeArray (err, array) ->
            if array.length is 0
              reply(Boom.notFound('Post not found'))
            else
              # Change updated_at
              post = _.extend(
                array[0],
                deleted: true,
                updated_at: new Date().toJSON()
              )

              # Save
              db.put(post.created_at, post, (err) ->
                if err
                  reply Boom.badImplementation(
                    "Post wasn't deleted correctly",
                    {err: err}
                  )
                else
                  reply post

                  # Enqueue updated post to be pushed to S3
                  jobsClient.push jobName: 'push_post_s3', post: post
              )
          )

  next()

exports.register.attributes =
  name: 'postsAPI'
  version: '1.0.0'
