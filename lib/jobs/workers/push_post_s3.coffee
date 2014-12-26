config = require 'config'
s3client = config.get('s3client')
server = require '../../../hapijs'

module.exports = (payload, cb) ->
  json = JSON.stringify payload.post, null, 4

  # If there's no post, just report it was finished successfully.
  unless json?
    cb()

  req = s3client.put("/posts/#{payload.post.id}.json", {
    'Content-Length': Buffer.byteLength(json)
    'Content-Type': 'application/json'
  })

  req.on 'response', (res) ->
    # Log errors.
    if res.statusCode isnt 200
      res.on 'data', (chunk) ->
        server.log ['error', 'jobQueue', 'push_post_s3'], {
          successful: false
          url: res.req.url
          statusCode: res.statusCode
          headers: res.heades
          body: chunk.toString()
        }
        cb(res.statusCode)
    else
      server.log ['info', 'jobQueue', 'push_post_s3'],
        successful: true,
        url: res.req.url
      cb()

  req.end json
