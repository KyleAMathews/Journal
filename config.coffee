knoxCopy = require 'knox-copy'
levelup = require 'levelup'
levelQuery = require('level-queryengine')
pathEngine = require('path-engine')
QueueClient = require('level-jobs/client')

config = {}

# Posts DB
config.db = levelup('./postsdb', valueEncoding: 'json')
config.wrappedDb = levelQuery(config.db)
config.wrappedDb.query.use(pathEngine())

# Jobs DB
config.jobsDb = levelup('./jobs_db')
config.jobsClient = QueueClient(config.jobsDb)

config.s3client = knoxCopy.createClient({
    key: process.env.AMAZON_KEY
    secret: process.env.AMAZON_SECRET
    bucket: process.env.S3_BUCKET
    region: process.env.S3_REGION || 'us-standard'
})

module.exports = config
