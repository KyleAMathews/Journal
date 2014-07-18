# Random app bootstrappy stuff.

config = require '../config'
require './jobs/worker_coordinator'

# Track memory and watch for memory leaks.
memwatch = require('memwatch')
memwatch.on 'lead', (info) ->
  config.server.log ['warn', 'memory', 'garbageCollection'], info

memwatch.on 'stats', (info) ->
  config.server.log ['debug', 'memory', 'garbageCollection'], info

# Override default 5 connections / domain limit.
require('https').globalAgent.maxSockets = 1000
require('http').globalAgent.maxSockets = 1000

# Sync posts with the app's Amazon S3 bucket
require './sync_posts'
