knoxCopy = require 'knox-copy'
levelup = require 'level'
levelQuery = require('level-queryengine')
pathEngine = require('path-engine')
async = require 'async'
_ = require 'underscore'
_str = require 'underscore.string'
fs = require 'fs'

config = require 'config'

s3PostsKeys = []
s3Posts = []
localPostsToStream = {}
s3PostsToSave = {}

exports.register = (server, options, next) ->
  db = server.plugins.dbs.postsDb
  wrappedDb = server.plugins.dbs.wrappedDb
  jobsClient = server.plugins.dbs.jobsClient

  if config.has('s3client')
    s3client = config.get('s3client')
    # The easiest way to fetch all files from a directory it seems is to first
    # use the knox_copy module to stream all the keys
    # and then fetch each file in turn.
    s3client.streamKeys(prefix: '/posts/').on('data', (key) ->
      if key isnt "posts/" # Ignore the directory
        s3PostsKeys.push key
    ).on 'end', ->
      # Once key streaming is finished, start fetching all the files.
      async.mapLimit s3PostsKeys, 25, getPostS3, (err, results) ->
        if err then server.log ['error', 'amazon_sync'], err
        obj = {}
        for result in results
          if result?
            obj[result.id] = result
        compareToLocal(obj)

    # Function to fetch files.
    getPostS3 = (key, callback) ->
      do (key) ->
        s3client.getFile key, (err, res) ->
          if err or not res?
            return callback(err)
          chunks = []
          res.on 'data', (chunk) -> chunks.push chunk
          res.on 'end', ->
            try
              post = JSON.parse Buffer.concat(chunks).toString()
            catch e
              server.log ['error', 'amazon_sync'], e
              callback(e)
            callback(err, post)

    # Compare each fetched posts to what exists locally and see what posts
    # if any should be transfered to S3 or locally.
    compareToLocal = (s3Posts) ->
      localPosts = {}
      db.createValueStream().on('data', (val) ->
        if val.body?
          localPosts[val.id] = val
          s3Post = s3Posts[val.id]
          # The post doesn't exist on S3. Queue to stream.
          unless s3Post?
            localPostsToStream[val.id] = val
          # There's been local updates, queue to stream to S3.
          else if s3Post.updated_at < val.updated_at
            localPostsToStream[val.id] = val
          # S3 has updates, queue to save locally.
          else if s3Post.updated_at > val.updated_at
            s3PostsToSave[val.id] = s3Post
          # No differences so nothing to be done.
          else if s3Post.updated_at is val.updated_at
            return
      ).on 'end', ->
        # Diff localposts array with s3Posts
        # so we can save new posts from S3 locally.
        for key in _.difference _.keys(s3Posts), _.keys(localPosts)
          s3PostsToSave[key] = s3Posts[key]

        # Diff localposts array with s3Posts so we can save new posts to S3.
        for key in _.difference _.keys(localPosts), _.keys(s3Posts)
          localPostsToStream[key] = localPosts[key]

        saveUpdatesFromS3()
        pushLocalUpdates()

    # Save any updates from S3 locally.
    saveUpdatesFromS3 = ->
      server.log ['info', 'amazon_sync'],
        "Saving #{_.keys(s3PostsToSave).length} posts from S3"
      for id, post of s3PostsToSave
        wrappedDb.put(post.created_at, post)

    # Queue to push local posts that are ahead of or don't exist on S3 yet.
    pushLocalUpdates = ->
      server.log ['info', 'amazon_sync'],
        "Pushing #{_.keys(localPostsToStream).length} posts to S3"
      for id, post of localPostsToStream
        jobsClient.push jobName: 'push_post_s3', post: post

  next()

exports.register.attributes =
  name: 'SyncAmazon'
  version: '1.0.0'