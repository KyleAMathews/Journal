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

config.server = server = new Hapi.Server(8081, '0.0.0.0', {
  cors: true
  json:
    space: 4
})

server.pack.register [
  {
    plugin: require 'lout'
  },
  {
    plugin: require './plugins/posts'
  },
  {
    plugin: require './plugins/search'
  },
  {
    plugin: require 'hapi-single-page-app-plugin'
    options:
      exclude: ['docs.*']
  },
  {
    plugin: require 'good'
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
], ->
  server.start ->
    console.log "Hapi server started @ #{server.info.uri}"
