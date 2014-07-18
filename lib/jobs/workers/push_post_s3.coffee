config = require '../../../config'

module.exports = (payload, cb) ->
  json = JSON.stringify payload.post, null, 4
  req = config.s3client.put("/posts/#{payload.post.id}.json", {
    'Content-Length': Buffer.byteLength(json)
    'Content-Type': 'application/json'
  })

  req.on 'response', (res) ->
    # Log errors.
    if res.statusCode isnt 200
      res.on 'data', (chunk) ->
        config.server.log ['error', 'jobQueue', 'push_post_s3'], {
          successful: false
          url: res.req.url
          statusCode: res.statusCode
          headers: res.heades
          body: chunk.toString()
        }
        cb(res.statusCode)
    else
      config.server.log ['info', 'jobQueue', 'push_post_s3'], successful: true, url: res.req.url
      cb()

  req.end json
