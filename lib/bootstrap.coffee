# Random app bootstrappy stuff.

memwatch = require('memwatch')
memwatch.on 'lead', (info) -> console.log info
memwatch.on 'stats', (info) ->
  console.log info
  console.log info.current_base / 1024 / 1024 + " MB"

# Override default 5 connections / domain limit.
require('https').globalAgent.maxSockets = 1000
require('http').globalAgent.maxSockets = 1000

# Sync posts with the app's Amazon S3 bucket
require './sync_posts'
