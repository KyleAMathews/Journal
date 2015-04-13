Joi = require 'joi'
es = require('event-stream')
_ = require 'underscore'
async = require 'async'
Boom = require 'boom'

config = require 'config'

exports.register = (server, options, next) ->

  eventsDb = server.plugins.dbs.eventsDb
  postsByIdDb = server.plugins.dbs.postsByIdDb
  postsByLastUpdatedDb = server.plugins.dbs.postsByLastUpdatedDb
  index = server.plugins.dbs.index

  jobsClient = server.plugins.dbs.jobsClient

  ## If there's no posts (e.g. fresh install of the application) add a sample one.
  #db.createKeyStream(limit: 1).pipe(es.writeArray (err, array) ->
    #if array.length is 0
      #post =
        #title: "Welcome to your new Journal!"
        #body: "This is a sample post. Try editing this post to see how things work.
          #You can use **Markdown** to format your posts.\n\nIf you find bugs
          #or otherwise need help, [post at an issue on Github](https://github.com/KyleAMathews/Journal/issues?state=open)."
        #created_at: new Date().toJSON()
        #updated_at: new Date().toJSON()
        #id: 1
        #deleted: false
        #starred: false
      #db.put post.id, post
  #)
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
          updated_since: Joi.date().raw().iso()
          start: Joi.date().raw().iso()
          until: Joi.date().raw().iso()
      handler: (request, reply) ->
        # User is querying for all posts changed since a certain date.
        # TODO — support this?
        if request.query.updated_since?
          reply 'NOT OK'
        else
          filteredPosts = []
          # Setting default date with Joi doesn't work
          # as it gets set to when the server starts.
          start = if request.query.start?
            request.query.start
          else
            new Date().toJSON()
          postsByLastUpdatedDb
            .createReadStream({
              lt: start
              reverse: true
              limit: request.query.limit
            })
            .on('data', (data) ->
              if filteredPosts.length >= request.query.limit
                return

              post = data.value
              unless post.deleted and post.draft
                filteredPosts.push post
            )
            .on('end', ->
              reply filteredPosts
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
        postsByIdDb.get(request.params.id, (err, value) ->
          if err
            reply Boom.notFound()
          else
            reply value
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
          title: Joi.string().min(1)
          body: Joi.string().min(1)
          starred: Joi.boolean()
          draft: Joi.boolean()
      handler: (request, reply) ->
        postsByIdDb.get request.params.id, (err, post) ->
          if err
            reply(Boom.notFound('Post not found'))
          else
            # Save event.
            updated_at = new Date().toJSON()
            old_updated_at = post.updated_at
            eventsDb.put "#{post.id}__#{updated_at}__postUpdated", _.extend(
              request.payload,
              updated_at: updated_at
            ), (err) ->
              if err
                return reply(
                  Boom.badImplementation("error saving update event", err)
                )
              else
                updatedPost = _.extend(
                  post,
                  request.payload,
                  updated_at: updated_at
                )

                # Update post indexes
                postsByIdDb.put updatedPost.id, updatedPost
                # Delete old updated_at post
                postsByLastUpdatedDb.del("#{old_updated_at}-#{post.id}")
                postsByLastUpdatedDb.put(
                  "#{updatedPost.updated_at}-#{updatedPost.id}",
                  updatedPost
                )

                # Update search index.
                index.update updatedPost

                reply updatedPost

                # Enqueue updated post to be pushed to S3
                #jobsClient.push jobName: 'push_post_s3', post: post

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
          created_at: Joi.date().iso().required()
          deleted: Joi.boolean().default(false)
          starred: Joi.boolean().default(false)
          draft: Joi.boolean()
          latitude: Joi.number().min(0).max(90)
          longitude: Joi.number().min(-180).max(180)

      handler: (request, reply) ->
        # Create new post and return
        newPost = request.payload
        newPost.created_at = newPost.created_at.toJSON()
        newPost.updated_at = newPost.created_at
        newPost.draft = true

        postsByIdDb.createValueStream()
          .pipe(es.writeArray (err, array) ->
            max = _.max(array, (post) -> post.id).id
            if max?
              newId = max + 1
            else
              newId = 1

            newPost.id = newId

            # Save event.
            eventsDb.put "#{newPost.id}__#{newPost.created_at}__postCreated",
              newPost,
              (err) ->
                response = reply(newPost)
                response.created("/posts/#{newPost.id}")

                # Add to post indexes
                postsByIdDb.put newPost.id, newPost

                postsByLastUpdatedDb.put(
                  "#{newPost.updated_at}-#{newPost.id}",
                  newPost
                )

                # Add to search index.
                index.add newPost
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
        postsByIdDb.get request.params.id, (err, post) ->
          if err
            reply(Boom.badImplementation("Error when getting post
              #{request.params.id}", {err: err}))
          else if not post?
            reply(Boom.notFound('Post not found'))
          else
            # Save event.
            eventsDb.put "#{post.id}__#{new Date().toJSON()}__postDeleted",
              {deleted_at: new Date().toJSON()},
              (err) ->
                reply(post)

                # Remove from post indexes
                postsByIdDb.del post.id

                # Remove from search index
                index.remove(post)

                postsByLastUpdatedDb.del("#{post.updated_at}-#{post.id}")

  next()

exports.register.attributes =
  name: 'postsAPI'
  version: '1.0.0'
