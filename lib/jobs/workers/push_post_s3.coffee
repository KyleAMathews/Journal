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
      console.log res.statusCode
      console.log res.headers
      console.log res.req.url
      res.on 'data', (chunk) ->
        console.log chunk.toString()
        cb(res.statusCode)
    else
      console.log 'pushed post to s3: ' + res.req.url
      cb()

  req.end json
