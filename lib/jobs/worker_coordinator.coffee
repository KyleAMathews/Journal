Jobs = require('level-jobs')
config = require '../../config'

worker = (payload, cb) ->
  try
    require("./workers/#{payload.jobName}")(payload, cb)
  catch e
    console.log e
    console.log payload

Jobs(config.jobsDb, worker, 10)
