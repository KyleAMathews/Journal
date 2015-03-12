Hapi = require 'hapi'
bunyan = require('bunyan')
Joi = require 'joi'
config = require 'config'

logger = bunyan.createLogger({
  name: 'journal'
  stream: process.stdout
  level: 'debug'
})

server = new Hapi.Server()

server.connection(
  {
    port: config.get('port')
    routes:
      cors: true
      json:
        space: 4
  }
)

server.register([
  {
    register: require './plugins/dbs'
  },
  {
    register: require './import_pepys'
  },
  {
    register: require './plugins/create_snapshots'
  }
  {
    register: require './plugins/posts'
  },
  {
    register: require './plugins/search'
  },
  #{
    #register: require './plugins/sync_amazon'
  #},
  {
    register: require 'hapi-single-page-app-plugin'
    options:
      exclude: ['docs.*']
      staticPath: './app/public'
  },
  {
    register: require 'good'
    options:
      reporters: [{
        reporter: require('good-console'),
        args:[{
          log: '*'
          request: '*'
          ops: '*'
          error: '*'
        }]
      }]
  }
], (err) ->
  if err then console.log err
  server.start (err) ->
    if err then console.log err
    console.log "Hapi server started @ #{server.info.uri}"

    # Start other app bootstrapy things.
    require './lib/bootstrap'
)

module.exports = server
