Hapi = require 'hapi'
Joi = require 'joi'

server = new Hapi.Server(8080, 'localhost')

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
    plugin: require 'good'
    options:
      subcribers:
        console: ['ops', 'request', 'log', 'error']
  }
], ->
  server.start ->
    console.log "Hapi server started @ #{server.info.uri}"
