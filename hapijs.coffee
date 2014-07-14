Hapi = require 'hapi'
Joi = require 'joi'
bunyan = require 'bunyan'
_ = require 'underscore'
useragent = require 'useragent'

server = new Hapi.Server(8081, '0.0.0.0', {
  cors: true
  json:
    space: 4
})

logger = bunyan.createLogger({
  name: "Journal"
  serializers:
    req: bunyan.stdSerializers.req
    res: (res) ->
      statusCode: res.statusCode
      headers: res._headers
})

server.pack.events.on('log', (event, tags) ->
  #console.log 'log event'
  console.log tags
  #logger.info(event.data)
)
server.pack.events.on('error', (event, tags) ->
  console.log tags
)

server.pack.events.on('request', (request, event, tags) ->
  #event =
    #request: request
    #event: event
    #tags: tags

  console.log tags
  # Various bad things happened.
  if tags.fatal
    logger.fatal event.data
  if tags.error
    logger.error event.data
  if tags.warn
    logger.warn event.data

  # Normal response
  if tags.response
    logger.info
      req: request.raw.req
      useragent: useragent.parse(request.raw.req.headers['user-agent'])
      res: request.raw.res
)

convertLogs = (event) ->
  LogEvent =
    event: event.data
    tags: event.tags

  LogEvent.request = event.request  if event.request
  LogEvent.event = LogEvent.event.toString()  if LogEvent.event instanceof Error
  if LogEvent.tags.indexOf("hapi") isnt -1
    LogEvent.comp = "hapi"
    Log.info LogEvent
  else if LogEvent.tags.indexOf("trace") isnt -1
    Log.trace LogEvent
  else if LogEvent.tags.indexOf("debug") isnt -1
    Log.debug LogEvent
  else if LogEvent.tags.indexOf("info") isnt -1
    Log.info LogEvent
  else if LogEvent.tags.indexOf("warn") isnt -1
    Log.warn LogEvent
  else if LogEvent.tags.indexOf("error") isnt -1
    Log.error LogEvent
  else if LogEvent.tags.indexOf("fatal") isnt -1
    Log.fatal LogEvent
  else
    Log.info LogEvent
  return
#Log = require("./log")

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
  }
], ->
  server.start ->
    logger.info info: server.info, "Hapi server started @ #{server.info.uri}"
