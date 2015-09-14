Hapi = require 'hapi'
#bunyan = require('bunyan')
Joi = require 'joi'
config = require 'config'

#logger = bunyan.createLogger({
  #name: 'journal'
  #stream: process.stdout
  #level: 'debug'
#})

server = new Hapi.Server()

server.on('response', (request) ->
  console.log(request.info.remoteAddress + ': ' + request.method.toUpperCase() + ' ' + request.url.path + ' --> ' + request.response.statusCode);
)

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
    register: require '../plugins/dbs'
  },
  #{
    #register: require '../import_pepys'
  #},
  {
    register: require('./graphql')
  }
  {
    register: require '../plugins/create_snapshots'
  }
  {
    register: require '../plugins/posts'
  },
  {
    register: require '../plugins/search'
  },
  #{
    #register: require '../plugins/sync_amazon'
  #},
  {
    register: require 'hapi-single-page-app-plugin'
    options:
      exclude: ['docs.*', 'graphql']
      staticPath: './app/public'
  },
  {
    register: require 'good'
    options:
      reporters: [{
        reporter: require('good-console'),
        events:
          log: '*'
          request: '*'
          ops: '*'
          error: '*'
      }]
  }
], (err) ->
  if err then console.log err
  server.start (err) ->
    if err then console.log err
    console.log "Hapi server started @ #{server.info.uri}"
    table = server.table()[0].table
    table.forEach (route) ->
      console.log route.path, "\t", route.method.toUpperCase()
)

module.exports = server
