knoxCopy = require 'knox-copy'
levelup = require 'levelup'
levelQuery = require('level-queryengine')
pathEngine = require('path-engine')

config = {}

config.db = levelup('./postsdb', valueEncoding: 'json')
config.wrappedDb = levelQuery(config.db)
config.wrappedDb.query.use(pathEngine())

config.s3client = knoxCopy.createClient({
    key: process.env.AMAZON_KEY
    secret: process.env.AMAZON_SECRET
    bucket: process.env.S3_BUCKET
    region: process.env.S3_REGION || 'us-standard'
})

module.exports = config
