Jobs = require('level-jobs')
_ = require 'underscore'
config = require 'config'
server = require '../../hapijs'
jobsDb = server.plugins.dbs.jobsDb

worker = (payload, cb) ->
  server.log ['info', 'jobQueue', 'processingJob'], payload
  try
    require("./workers/#{payload.jobName}")(payload, cb)
  catch e
    server.log ['error', 'jobQueue'], _.extend {}, e, payload: payload

Jobs(jobsDb, worker, 10)
