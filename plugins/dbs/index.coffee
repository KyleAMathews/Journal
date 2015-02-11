knoxCopy = require 'knox-copy'
levelup = require 'level'
QueueClient = require('level-jobs/client')
config = require 'config'
lunr = require 'lunr'
_ = require 'underscore'

posts = {}
sortedPosts = []
index = lunr ->
  @field('title', boost: 10)
  @field('body')

exports.register = (server, options, next) ->

  jobsDb = levelup(config.get('db.jobs'))
  postsDb = levelup(config.get('db.posts'), valueEncoding: 'json')

  syncPosts = ->
    console.log "Syncing posts"
    postsDb.createReadStream()
      .on 'data', (data) ->
        posts[data.value.id] = data.value
        index.add(data.value)
      .on 'end', ->
        server.expose('posts', posts)
        console.log "posts loading done"
        sortedPosts = _.values(_.extend({}, posts))
        sortedPosts = _.sortBy(sortedPosts, (post) -> post.created_at).reverse()
        server.expose('sortedPosts', sortedPosts)

  syncPosts()
  server.expose('syncPosts', syncPosts)

  jobsClient = QueueClient(jobsDb)

  if config.has('amazon.key')
    s3client = knoxCopy.createClient({
      key: config.get('amazon.key')
      secret: config.get('amazon.secret')
      bucket: config.get('amazon.bucket')
      region: config.get('amazon.region')
    })

    server.expose('s3client', s3client)

  server.expose('jobsDb', jobsDb)
  server.expose('jobsClient', jobsClient)
  server.expose('postsDb', postsDb)
  server.expose('posts', posts)
  server.expose('sortedPosts', sortedPosts)
  server.expose('index', index)

  next()

exports.register.attributes =
  name: 'dbs'
  version: '1.0.0'
