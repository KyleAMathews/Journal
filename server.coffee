express = require 'express'
mongoose = require 'mongoose'
passport = require 'passport'
RedisStore = require('connect-redis')(express)
require './post_schema'
require './user_schema'
async = require 'async'
_ = require 'underscore'
# Import Underscore.string to separate object, because there are conflict functions (include, reverse, contains)
_.str = require('underscore.string')
# Mix in non-conflict functions to Underscore namespace if you want
_.mixin(_.str.exports())

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

# Synchronize models with Elastic Search.
Post = mongoose.model 'post'
#stream = Post.synchronize()
#count = 0;

#stream.on('data', (err, doc) ->
    #count++
#)
#stream.on('close', ->
    #console.log('indexed ' + count + ' documents!')
#)
#stream.on('error', (err) ->
    #console.log(err)
#)

# Routes.
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
  created = if req.query.created? then req.query.created else new Date()
  if req.query.id
    findById(req.query.id, res, req)
  else if req.query.nid
    findByNid(req.query.nid, res, req)
  else
    Post.find()
      .limit(10)
      .where('created').lt(created)
      .notEqualTo('deleted', true)
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
        else
          console.err 'Error creating new post', err

app.put '/posts/:id', (req, res) ->
  console.log 'updating an post'
  Post = mongoose.model 'post'
  Post.findById req.params.id, (err, post) ->
    unless err or not post? or post._user.toString() isnt req.user._id.toString()
      for k,v of req.body
        if k is 'id' then continue
        post[k] = v
      post.changed = new Date()
      post.save (err) ->
        if err then console.err err
        res.json {
          saved: true
          changed: post.changed
        }
    else
      console.err 'update error', err

app.del '/posts/:id', (req, res) ->
  res.send 'hello world'

app.get '/drafts', (req, res) ->
  Draft = mongoose.model 'draft'
  Draft.find()
    .where( '_user', req.user._id.toString())
    .desc('created')
    .run (err, drafts) ->
      console.log 'drafts query done'
      unless err or not drafts?
        for draft in drafts
          draft.setValue('id', draft.getValue('_id'))
        res.json drafts
      else
        res.json 'found nothing'

app.post '/drafts', (req, res) ->
  console.log 'saving new draft'
  Draft = mongoose.model 'draft'
  draft = new Draft()
  for k,v of req.body
    draft[k] = v
  draft._user = req.user._id.toString()

  draft.created = new Date()
  draft.changed = draft.created
  console.log draft
  draft.save (err) ->
    unless err
      res.json id: draft._id, created: draft.created, changed: draft.changed
    else
      console.log 'error', err

app.put '/drafts/:id', (req, res) ->
  console.log 'updating a draft'
  Draft = mongoose.model 'draft'
  Draft.findById req.params.id, (err, draft) ->
    unless err or not draft? or draft._user.toString() isnt req.user._id.toString()
      for k,v of req.body
        if k is 'id' then continue
        draft[k] = v
      draft.changed = new Date()
      draft.save()
      res.json {
        saved: true
        changed: draft.changed
      }

app.del '/drafts/:id', (req, res) ->
  console.log 'deleting a draft'
  Draft = mongoose.model 'draft'
  Draft.findById req.params.id, (err, draft) ->
    unless err or not draft? or draft._user.toString() isnt req.user._id.toString()
      console.log draft
      draft.remove()
      res.send 'draft successfully deleted'

# Search
app.get '/search', (req, res) ->
  if req.isAuthenticated()
    res.render 'index'
  else
    res.redirect '/login'

app.get '/search/:query', (req, res) ->
  if req.isAuthenticated()
    if req.headers.accept? and req.headers.accept.indexOf('text/html') isnt -1
      res.render 'index'
    else
      Post = mongoose.model 'post'
      Post.search({
        from: 0
        size: 40
        query:
          query_string:
            fields: ['title', 'body']
            query: req.params.query
        filter:
          #and: [
            term:
              _user: req.user._id.toString()
            #,
            #{
            #range:
              #created:
                #from: 1262304000000
                #to: 1293840000000
            #}
            #]
        facets:
          year:
            date_histogram:
              field: 'created'
              interval: 'year'
          month:
            date_histogram:
              field: 'created'
              interval: 'month'
        highlight:
          fields:
            title: {"fragment_size" : 300}
            body: {"fragment_size" : 200}
      }, (err, posts) ->
        if err then console.log err
        res.json posts
      )
  else
    res.redirect '/login'

# Listen on port 3000 or a passed-in port
args = process.argv.splice(2)
if args[0]? then port = parseInt(args[0], 10) else port = 3000
app.listen(port)
console.log("Express server listening on port %d in %s mode", app.address().port, app.settings.env)
