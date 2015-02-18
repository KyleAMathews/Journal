Joi = require 'joi'
es = require('event-stream')
_ = require 'underscore'
async = require 'async'
Boom = require 'boom'

config = require 'config'

exports.register = (server, options, next) ->
  db = server.plugins.dbs.postsDb
  posts = server.plugins.dbs.posts
  sortedPosts = server.plugins.dbs.sortedPosts
  index = server.plugins.dbs.index
  syncPosts = server.plugins.dbs.syncPosts
  jobsClient = server.plugins.dbs.jobsClient

  ## If there's no posts (e.g. fresh install of the application) add a sample one.
  db.createKeyStream(limit: 1).pipe(es.writeArray (err, array) ->
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
      db.put post.id, post
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
        # TODO — support this?
        if request.query.updated_since?
          reply 'NOT OK'

        else
          filteredPosts = []
          for post in server.plugins.dbs.sortedPosts
            # Filter out deleted posts and posts newer than the start date.
            if not post.deleted and
                post.created_at < request.query.start.toJSON()
              filteredPosts.push post
              if filteredPosts.length >= request.query.limit
                break

          reply filteredPosts

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
        if posts[request.params.id]?
          reply posts[request.params.id]
        else
          reply Boom.notFound()

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
          title: Joi.string().min(1)
          body: Joi.string().min(1)
          starred: Joi.boolean()
      handler: (request, reply) ->
        db.get request.params.id, (err, post) ->
          if err
            reply(Boom.badImplementation("Error when getting post
              #{request.params.id}", {err: err}))
          else if not post?
            reply(Boom.notFound('Post not found'))
          else
            # Change updated_at
            patchedPost = _.extend(
              post,
              request.payload,
              updated_at: new Date().toJSON()
            )

            # Save
            db.put(patchedPost.id, patchedPost, (err) ->
              if err
                reply Boom.badImplementation(
                  "Post patch didn't save correctly",
                  {err: err}
                )
              else
                reply patchedPost

                # Update in-memory version of posts.
                posts[patchedPost.id] = patchedPost

                # Resync in-memory version of db to ensure correctness.
                syncPosts()

                # Enqueue updated post to be pushed to S3
                jobsClient.push jobName: 'push_post_s3', post: post
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
        newPost.draft = true

        db.createValueStream()
          .pipe(es.writeArray (err, array) ->
            max = _.max(array, (post) -> post.id).id
            if max?
              newId = max + 1
            else
              newId = 1
            newPost.id = newId

            # Save
            db.put(newPost.id, newPost, (err) ->
              response = reply(newPost)
              response.created("/posts/#{newPost.id}")

              # Update in-memory version of posts.
              posts[newPost.id] = newPost

              # Resync in-memory version of db
              syncPosts()

              # Enqueue updated post to be pushed to S3
              jobsClient.push jobName: 'push_post_s3', post: newPost
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
        db.get request.params.id, (err, post) ->
          if err
            reply(Boom.badImplementation("Error when getting post
              #{request.params.id}", {err: err}))
          else if not post?
            reply(Boom.notFound('Post not found'))
          else
            # Change updated_at
            deletedPost = _.extend(
              post,
              updated_at: new Date().toJSON()
              deleted: true
            )

            # Save
            db.put(deletedPost.id, deletedPost, (err) ->
              if err
                reply Boom.badImplementation(
                  "Post patch wasn't deleted correctly",
                  {err: err}
                )
              else
                reply deletedPost

                # Update in-memory version of posts.
                posts[deletedPost.id] = deletedPost

                # Resync in-memory version of db to ensure correctness.
                syncPosts()

                # Enqueue updated post to be pushed to S3
                jobsClient.push jobName: 'push_post_s3', post: post
            )

  next()

exports.register.attributes =
  name: 'postsAPI'
  version: '1.0.0'
