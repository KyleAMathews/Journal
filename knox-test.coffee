knoxCopy = require 'knox-copy'
knox = require 'knox-copy'
glob = require 'glob'
path = require 'path'
gm = require 'gm'
mime = require 'mime'
async = require 'async'
fs = require 'fs'
bytes = require 'bytes'

client = knox.createClient({
    key: 'AKIAJRKQNAQ3TNK7ZTHA'
    secret: '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'
    bucket: 'kyle-journal'
    region: 'us-west-1'
})

#copyClient = knoxCopy.createClient({
    #key: 'AKIAJRKQNAQ3TNK7ZTHA'
  #, secret: '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'
  #, bucket: 'kyle-test123'
#})

glob('./attachments/attachments/kylemathews/*', (err, matches) ->
  async.eachLimit matches, 5, (match, callback) ->
    unless fs.statSync(match).isFile() then return callback()
    retinaPathName = "/pictures/" + path.basename(match, path.extname(match)) + "@2x" + path.extname(match)
    originalPathName = "/pictures/" + path.basename(match, path.extname(match)) + "_original" + path.extname(match)
    pathName = "/pictures/" + path.basename(match)
    contentType = mime.lookup(match)
    do (match, contentType, retinaPathName, callback) ->
      gm(match)
        .autoOrient()
        .resize('1122', '1000000', ">")
        .stream (err, stdout, stderr) ->
          if err then return console.log err
          chunks = []
          stdout.on 'data', (chunk) ->
            chunks.push chunk
          stdout.on 'end', ->
            image = Buffer.concat chunks

            req = client.put retinaPathName, {
              'Content-Length': image.length
              'x-amz-acl': 'public-read'
              'Content-Type': contentType
            }
            req.on 'response', (res) ->
              if res.statusCode is 200
                console.log "Saved retina version to #{res.req.url}"
              else
                console.log "File didn't save correctly for #{res.req.url}, statusCode: #{res.statusCode}"

              callback()

            req.end image

    #console.log "Uploading #{originalPathName}: #{bytes(fs.statSync(match).size)}"
    #client.putFile match, originalPathName, { 'x-amz-acl': 'public-read' }, (err, res) ->
      #res.resume()
      #if res.statusCode is 200
        #console.log "Saved file to #{res.req.url}"
      #callback()
)

#console.log client.https('/obj.json')
#object = { foo: "bar" }
#string = JSON.stringify(client)
#console.log string
#req = client.put('obj.json', {'Content-Length': string.length,'Content-Type': 'text/plain', 'x-amz-acl': 'public-read'})

#req.on 'response', (res) ->
  #console.log res.statusCode
  #console.log res.headers
  #res.on 'data', (chunk) ->
    #console.log chunk.toString()

#req.end string

#console.log copyClient.get
#copyClient.streamKeys().on 'data', (key) ->
  #console.log key
  #client.getFile "/#{key}", (err,res) ->
    #console.log res.statusCode
    #console.log res.headers
    #res.on 'data', (chunk) -> console.log chunk.toString()

#client.getFile "/lb.opml", (err, res) ->
  #console.log err
  #console.log res.statusCode
  #console.log res.headers
  #res.on 'data', (chunk) -> console.log chunk
