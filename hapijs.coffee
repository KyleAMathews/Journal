Hapi = require 'hapi'
bunyan = require('bunyan')
Joi = require 'joi'
config = require './config'
bootstrap = require './lib/bootstrap'

logger = bunyan.createLogger({
  name: 'journal'
  stream: process.stdout
  level: 'debug'
})

config.server = server = new Hapi.Server()
server.connection(
  {
    port: 8081
    routes:
      cors: true
      json:
        space: 4
  }
)

server.register([
  {
    register: require './plugins/posts'
  },
  {
    register: require './plugins/search'
  },
  {
    register: require 'hapi-single-page-app-plugin'
    options:
      exclude: ['docs.*']
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
)
