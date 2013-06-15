url = require("url")

# Set these environmental variables to specify Mongo, Redis, and ElasticSearch 
# servers different than the defaults. Env variables that can be set are 
# MONGO_URL, REDIS_URL, ELASTICSEARCH_URL, and ELASTICSEARCH_INDEX.

# All URLs should be of the form 'protocol://host' (at a minimum), or 
# url.parse() will not parse them correctly.

config = mongo_url: process.env.MONGO_URL ?  "mongodb://localhost/journal"
config.redis_url = process.env.REDIS_URL ? "redis://bogususer:@localhost"          #Bogus user to set a blank default password
config.redis_url = url.parse(config.redis_url)

config.elasticSearchHost = process.env.ELASTICSEARCH_URL ? 'http://localhost'
config.elasticSearchHost = url.parse(config.elasticSearchHost)
config.elasticSearchHost.index = process.env.ELASTICSEARCH_INDEX ? 'journal_posts'
config.elasticSearchHost.protocol = config.elasticSearchHost.protocol.slice(0, -1) # url.parse leaves a colon on the end of the protocol, which node-elastical has a problem with
config.elasticSearchHost.host = config.elasticSearchHost.hostname # url.parse leaves the port at the end of host (but not hostname), which node-elastical has a problem with

module.exports = config
