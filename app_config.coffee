url = require("url")

# Set these environmental variables to specify Mongo, Redis, and ElasticSearch 
# servers different than the defaults. Env variables that can be set are 
# MONGO_URL, REDIS_URL, ELASTICSEARCH_URL, and ELASTICSEARCH_INDEX.
config = mongo_url: process.env.MONGO_URL ?  "mongodb://localhost/journal"
config.redis_url = process.env.REDIS_URL ? "redis://bogususer:@localhost"          #Bogus user to set a blank default password
config.redis_url = url.parse(config.redis_url)

config.elasticSearchHost = process.env.ELASTICSEARCH_URL ? 'localhost'
config.elasticSearchHost = url.parse(config.elasticSearchHost)
config.elasticSearchHost.index = process.env.ELASTICSEARCH_INDEX ? 'journal_posts'

module.exports = config
