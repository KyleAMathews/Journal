# Random app bootstrappy stuff.
config = require 'config'
#require './jobs/worker_coordinator'

# Track memory and watch for memory leaks.
#memwatch = require('memwatch')
#memwatch.on 'lead', (info) ->
  #server.log ['warn', 'memory', 'garbageCollection'], info

#memwatch.on 'stats', (info) ->
  #server.log ['debug', 'memory', 'garbageCollection'], info

# Override default 5 connections / domain limit.
require('https').globalAgent.maxSockets = 1000
require('http').globalAgent.maxSockets = 1000
