config = require '../app_config'
fs = require 'fs'
gm = require 'gm'

exports.post = (req, res) ->
  Attachment = config.mongoose.model 'attachment'
  tmpFile = req.files.attachment.file.path
  # TODO need real usernames... plus the user object needs loaded into the dashboard.
  targetPath = './attachments/kylemathews/' + req.files.attachment.file.name
  smallPath = './attachments/kylemathews/small/' + req.files.attachment.file.name

  # TODO start streaming original immediately to S3
  # Then convert the smaller and stream it. So the code here should stay about the same.
  # Move file from the temporary location to our attachments directory.
  fs.rename tmpFile, targetPath, (err) ->
    if err
      console.log err
      res.json "Couldn't copy file", 500
    else
      # Save uid -> file path mapping to mongo.
      attachment = new Attachment()
      attachment.path = targetPath
      attachment.pathSmall = smallPath
      attachment.uid = req.body.attachment.uid
      attachment.created = new Date()
      attachment._user = req.user._id.toString()
      attachment.save (err) ->
        if err
          console.log err
          res.json "Couldn't save file mapping to MongoDB", 500
        else
          res.json 'File uploaded to: ' + targetPath + ' - ' + req.files.attachment.file.size + ' bytes'

      # Create smaller version.
      gm(targetPath)
        .autoOrient()
        .resize('476', '1000000', ">")
        .write(smallPath, (err, stdout, stderr, command) ->
          if err then console.log err
          console.log 'gm command', command
      )

exports.getSmall = (req, res) ->
  Attachment = config.mongoose.model 'attachment'
  Attachment.find({ uid: req.params.id })
    .run (err, attachments) ->
      if err then console.log err
      if attachments.length > 0
        res.sendfile(attachments[0].pathSmall)
      else
        res.send "File not found", 404

exports.getOriginal = (req, res) ->
  Attachment = config.mongoose.model 'attachment'
  Attachment.find({ uid: req.params.id })
    .run (err, attachments) ->
      if err then console.log err
      if attachments.length > 0
        res.sendfile(attachments[0].path)
      else
        res.send "File not found", 404
