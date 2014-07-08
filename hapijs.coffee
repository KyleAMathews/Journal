Hapi = require 'hapi'
Joi = require 'joi'

server = new Hapi.Server(8081, '0.0.0.0', {
  cors: true
  json:
    space: 4
})

# Port the react example over and pull from here
# For caching latest, just store in localstorage as "latest" and pull that first
# do same with individual posts

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
      subcribers:
        console: ['ops', 'request', 'log', 'error']
  }
], ->
  server.start ->
    console.log "Hapi server started @ #{server.info.uri}"
