mongoose = require 'mongoose'

# nid routes.
exports.getNidPost = (req, res) ->
  if req.isAuthenticated()
    if req.headers.accept? and req.headers.accept.indexOf('text/html') isnt -1
      res.render 'index'
    else
      findByNid(req.params.nid, res)
  else
    res.redirect '/login'

exports.getNidPostEdit = (req, res) ->
  if req.isAuthenticated()
    if req.headers.accept? and req.headers.accept.indexOf('text/html') isnt -1
      res.render 'index'
    else
      findByNid(req.params.nid, res)
  else
    res.redirect '/login'

exports.post = (req, res) ->
  console.log 'saving new post'
  Post = mongoose.model 'post'
  post = new Post()
  for k,v of req.body
    post[k] = v
  post._user = req.user._id.toString()

  # Figure out max nid.
  Post.find({},['nid'])
    .desc('nid')
    .limit(1)
    .run (err, postWithMaxNid) ->
      post.nid = 1
      if postWithMaxNid[0]?
        postWithMaxNid = postWithMaxNid[0]
        console.log postWithMaxNid
        console.log postWithMaxNid.nid
        post.nid = postWithMaxNid.nid + 1

      unless post.created?
        post.created = new Date()
      unless post.changed?
        post.changed = post.created
      post.save (err) ->
        unless err?
          res.json id: post._id, created: post.created, nid: post.nid
        else
          console.error 'Error creating new post', err
          res.json(500, err)

exports.put = (req, res) ->
  console.log 'updating an post'
  Post = mongoose.model 'post'
  Post.findById req.params.id, (err, post) ->
    unless err or not post? or post._user.toString() isnt req.user._id.toString()
      for k,v of req.body
        if k is 'id' then continue
        post[k] = v
      post.changed = new Date()
      post.save (err) ->
        if err
          console.error err
          res.json 500, error: "The post wasn't saved correctly"
        res.json {
          saved: true
          changed: post.changed
        }
    else
      console.log 'update error', err

exports.delete = (req, res) ->
  Post = mongoose.model 'post'
  Post.findById req.params.id, (err, post) ->
    unless err or not post? or post._user.toString() isnt req.user._id.toString()
      post.changed = new Date()
      post.deleted = true
      post.save (err) ->
        if err
          console.error err
          res.json 500, error: "The post wasn't saved correctly"
        res.json {
          deleted: true
        }
    else
      console.log 'update error', err

exports.list = (req, res) ->
  unless req.isAuthenticated()
    res.send(401)
  else
    Post = mongoose.model 'post'
    created = if req.query.created? then req.query.created else new Date()
    # If user wants only posts changed after a certain date.
    if req.query.changed
      recentPostChanges(req, res)
    # If the user only wants draft posts.
    else if req.query.draft
      postDrafts(req, res)
    else if req.query.starred
      starredPosts(req, res)
    else if req.query.id
      findById(req.query.id, res, req)
    else if req.query.nid
      findByNid(req.query.nid, res, req)
    else
      Post.find()
        .limit(10)
        .where('created').lt(created)
        .notEqualTo('deleted', true)
        .notEqualTo('draft', true)
        .where( '_user', req?.user._id.toString())
        .desc('created')
        .run (err, posts) ->
          console.log 'query done'
          unless err or not posts?
            for post in posts
              post.setValue('id', post.getValue('_id'))
            res.json posts
          else
            res.json ''

exports.getPost = (req, res) ->
  if req.isAuthenticated()
    if req.headers.accept? and req.headers.accept.indexOf('text/html') isnt -1
      res.render 'index'
    else
      findById(req.params.id, res, req)
  else
    res.redirect '/login'

exports.newPost = (req, res) ->
  if req.isAuthenticated()
    res.render 'index'
  else
    res.redirect '/login'

findById = (id, res, req) ->
  Post = mongoose.model 'post'
  Post.findById id, (err, post) ->
    unless err or not post? or post?._user.toString() isnt req.user._id.toString()
      post.setValue('id', post.getValue('_id'))
      res.json post
    else
      console.log err
      res.json 'found nothing'

findByNid = (nid, res, req) ->
  Post = mongoose.model 'post'
  Post.find { nid: nid }, (err, post) ->
    post = post[0]
    unless err or not post? or post?._user.toString() isnt req?.user._id.toString()
      post.setValue('id', post.getValue('_id'))
      res.json post
    else
      console.log err
      res.json 'found nothing'

recentPostChanges = (req, res) ->
  Post = mongoose.model 'post'
  changed = if req.query.changed? then req.query.changed else new Date()
  oldest = if req.query.oldest? then req.query.oldest else new Date()
  Post.find()
    .where('changed').gt(changed)
    .where('created').gt(oldest)
    .notEqualTo('deleted', true)
    .where( '_user', req.user._id.toString())
    .desc('created')
    .run (err, posts) ->
      console.log 'posts changed query done'
      unless err or not posts?
        for post in posts
          post.setValue('id', post.getValue('_id'))
        res.json posts
      else
        res.json ''

postDrafts = (req, res) ->
  Post = mongoose.model 'post'
  Post.find()
    .notEqualTo('deleted', true)
    .where('draft', true)
    .where( '_user', req?.user._id.toString())
    .desc('created')
    .run (err, posts) ->
      console.log 'drafts query done'
      unless err or not posts?
        for post in posts
          post.setValue('id', post.getValue('_id'))
        res.json posts
      else
        res.json ''

starredPosts = (req, res) ->
  Post = mongoose.model 'post'
  Post.find()
    .notEqualTo('deleted', true)
    .where('starred', true)
    .where( '_user', req?.user._id.toString())
    .desc('created')
    .run (err, posts) ->
      console.log 'starred query done'
      unless err or not posts?
        for post in posts
          post.setValue('id', post.getValue('_id'))
        res.json posts
      else
        res.json ''
