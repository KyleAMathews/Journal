knoxCopy = require 'knox-copy'
levelup = require 'levelup'
levelQuery = require('level-queryengine')
pathEngine = require('path-engine')
QueueClient = require('level-jobs/client')
config = require 'config'

exports.register = (server, options, next) ->

  jobsDb = levelup(config.get('db.jobs'))
  postsDb = levelup(config.get('db.posts'), valueEncoding: 'json')

  jobsClient = QueueClient(jobsDb)

  wrappedDb = levelQuery(postsDb)
  wrappedDb.query.use(pathEngine())

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
  server.expose('wrappedDb', wrappedDb)
  next()

exports.register.attributes =
  name: 'dbs'
  version: '1.0.0'
