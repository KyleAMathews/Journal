express = require 'express'
mongoose = require 'mongoose'
passport = require 'passport'
RedisStore = require('connect-redis')(express)
require './post_schema'
require './user_schema'
_ = require 'underscore'

app = express.createServer()

# Setup Express middleware.
app.configure ->
  app.set 'views', __dirname + '/views'
  app.set 'view engine', 'jade'
  app.use express.cookieParser()
  app.use express.responseTime()
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use express.session({ store: new RedisStore, secret: 'Make Stuff', cookie: { maxAge: 1209600000 }}) # two weeks
  app.use passport.initialize()
  app.use passport.session()
  app.use app.router
  app.use express.static __dirname + '/public'

app.get '/', (req, res) ->
  if req.isAuthenticated()
    res.render 'index'
  else
    res.redirect '/login'
app.get '/node/:nid', (req, res) ->
  if req.isAuthenticated()
    if req.headers.accept? and req.headers.accept.indexOf('text/html') isnt -1
      res.render 'index'
    else
      findByNid(req.params.nid, res)
  else
    res.redirect '/login'

app.get '/node/:nid/edit', (req, res) ->
  if req.isAuthenticated()
    if req.headers.accept? and req.headers.accept.indexOf('text/html') isnt -1
      res.render 'index'
    else
      findByNid(req.params.nid, res)
  else
    res.redirect '/login'

app.get '/posts/new', (req, res) ->
  if req.isAuthenticated()
    res.render 'index'
  else
    res.redirect '/login'
app.get '/login', (req, res) ->
  unless req.isAuthenticated()
    json =
      errorMessages: []
    messages = req.flash()
    if messages.error?
      json.errorMessages = messages.error
    res.render 'login', json
  else
    res.redirect '/'
app.post '/login', passport.authenticate('local',
  {
    successRedirect: '/'
    failureRedirect: '/login'
    failureFlash: true
  })
app.get '/logout', (req, res) ->
  req.logout()
  res.redirect '/login'

findById = (id, res, req) ->
  Post = mongoose.model 'post'
  Post.findById id, (err, post) ->
    unless err or not post? or post._user.toString() isnt req.user._id.toString()
      post.setValue('id', post.getValue('_id'))
      res.json post

findByNid = (nid, res, req) ->
  Post = mongoose.model 'post'
  Post.find { nid: nid }, (err, post) ->
    post = post[0]
    unless err or not post? or post._user.toString() isnt req.user._id.toString()
      post.setValue('id', post.getValue('_id'))
      res.json post
    else
      console.log err
      res.json 'found nothing'

app.get '/posts', (req, res) ->
  Post = mongoose.model 'post'
  skip = if req.query.skip? then req.query.skip else 0
  if req.query.id
    findById(req.query.id, res, req)
  else if req.query.nid
    findByNid(req.query.nid, res, req)
  else
    Post.find()
      .limit(10)
      .skip(skip)
      .where( '_user', req.user._id.toString())
      .desc('created')
      .run (err, posts) ->
        console.log 'query done'
        unless err or not posts?
          for post in posts
            post.setValue('id', post.getValue('_id'))
          res.json posts
        else
          res.json 'found nothing'

#User = mongoose.model 'user'
#user = new User()
#user.name = "person"
#user.email = "email"
#user.created = new Date()
#user.changed = new Date()
#user.setPassword('a password', ->
  #user.save (err) ->
    #if err then console.err err
    #else
      #console.log 'user saved!'
#)

app.post '/posts', (req, res) ->
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
      post.changed = post.created
      post.save (err) ->
        unless err
          res.json id: post._id, created: post.created, nid: post.nid

app.put '/posts/:id', (req, res) ->
  console.log 'updating an post'
  Post = mongoose.model 'post'
  Post.findById req.params.id, (err, post) ->
    unless err or not post? or post._user.toString() isnt req.user._id.toString()
      for k,v of req.body
        if k is 'id' then continue
        post[k] = v
      post.changed = new Date()
      post.save()
      res.json {
        saved: true
        changed: post.changed
      }

app.del '/posts/:id', (req, res) ->
  res.send 'hello world'

# Listen on port 3000 or a passed-in port
args = process.argv.splice(2)
if args[0]? then port = parseInt(args[0], 10) else port = 3000
app.listen(port)
console.log("Express server listening on port %d in %s mode", app.address().port, app.settings.env)
