Jobs = require('level-jobs')
_ = require 'underscore'
config = require '../../config'

worker = (payload, cb) ->
  config.server.log ['info', 'jobQueue', 'processingJob'], payload
  try
    require("./workers/#{payload.jobName}")(payload, cb)
  catch e
    config.server.log ['error', 'jobQueue'], _.extend {}, e, payload: payload

Jobs(config.jobsDb, worker, 10)
