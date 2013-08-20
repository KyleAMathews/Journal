config = require './app_config'

express = require 'express'
mongoose = require 'mongoose'
passport = require 'passport'
RedisStore = require('connect-redis')(express)
redis = require 'redis'
require './post_schema'
require './user_schema'
async = require 'async'
flash = require 'connect-flash'
fs = require 'fs'
gm = require 'gm'
_ = require 'underscore'
# Import Underscore.string to separate object, because there are conflict functions (include, reverse, contains)
_.str = require('underscore.string')
# Mix in non-conflict functions to Underscore namespace if you want
_.mixin(_.str.exports())

app = express()

# Setup RedisStore for sessions
sessionStore = new RedisStore({
  host: config.redis_url.hostname
  port: config.redis_url.port
  pass: config.redis_url.auth.split(':')[1]
})

# Setup redis client
rclient = redis.createClient()

# Setup Express middleware.
app.configure ->
  app.set 'views', __dirname + '/views'
  app.set 'view engine', 'jade'
  app.use express.compress()
  app.use express.cookieParser()
  app.use express.responseTime()
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use express.session({ store: sessionStore, secret: 'Make Stuff', cookie: { maxAge: 1209600000 }}) # two weeks
  app.use passport.initialize()
  app.use passport.session()
  app.use flash()
  app.use app.router
  app.use express.static 'public'

# Routes.
app.get '/', (req, res) ->
  if req.isAuthenticated()
    # TODO this his hacky, replace with real environment variable system.
    unless process.platform is "darwin" or app.settings.env is "development" # e.g. we're on a mac so developing.
      res.render 'index', manifest: '/appcache.appcache'
    else
      res.render 'index'
  else
    res.redirect '/login'

# Simple ping route so client can detect if it's online or not.
app.get '/ping', (req, res) ->
  if req.isAuthenticated()
    res.send(200)
  else
    res.send(403)

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

app.get '/posts/:id', (req, res) ->
  if req.isAuthenticated()
    if req.headers.accept? and req.headers.accept.indexOf('text/html') isnt -1
      res.render 'index'
    else
      findById(req.params.id, res, req)
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

app.get '/posts', (req, res) ->
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

app.post '/attachments', (req, res) ->
  Attachment = mongoose.model 'attachment'
  tmpFile = req.files.attachment.file.path
  targetPath = './attachments/kylemathews/' + req.files.attachment.file.name
  smallPath = './attachments/kylemathews/small/' + req.files.attachment.file.name

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

app.get '/attachments/:id', (req, res) ->
  Attachment = mongoose.model 'attachment'
  Attachment.find({ uid: req.params.id })
    .run (err, attachments) ->
      if err then console.log err
      if attachments.length > 0
        res.sendfile(attachments[0].pathSmall)
      else
        res.send "File not found", 404

app.get '/attachments/:id/original', (req, res) ->
  Attachment = mongoose.model 'attachment'
  Attachment.find({ uid: req.params.id })
    .run (err, attachments) ->
      if err then console.log err
      if attachments.length > 0
        res.sendfile(attachments[0].path)
      else
        res.send "File not found", 404

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
      unless post.changed?
        post.changed = post.created
      post.save (err) ->
        unless err?
          res.json id: post._id, created: post.created, nid: post.nid
        else
          console.error 'Error creating new post', err
          res.json(500, err)

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
        if err
          console.error err
          res.json 500, error: "The post wasn't saved correctly"
        res.json {
          saved: true
          changed: post.changed
        }
    else
      console.log 'update error', err

app.del '/posts/:id', (req, res) ->
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

app.get '/drafts', (req, res) ->
  if req.isAuthenticated()
    if req.headers.accept? and req.headers.accept.indexOf('text/html') isnt -1
      res.render 'index'
    else
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
  else
    res.redirect '/login'

app.get '/drafts/:id', (req, res) ->
  if req.isAuthenticated()
    if req.headers.accept? and req.headers.accept.indexOf('text/html') isnt -1
      res.render 'index'
  else
    res.redirect '/login'

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
      console.error 'error', err
      res.json 500, err

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
    if req.headers.accept? and req.headers.accept.indexOf('text/html') isnt -1
      res.render 'index'
  else
    res.redirect '/login'

recordQuery = (query, user) ->
  key = "query_#{ user }_#{ (Math.random() * 10000).toString().split('.')[0] }"
  rclient.set key, query
  # expire query data after one month.
  rclient.expire key, 2592000

app.get '/search/queries', (req, res) ->
  if req.isAuthenticated()
    if req.headers.accept? and req.headers.accept.indexOf('text/html') isnt -1
      res.render 'index'
    else
      # Fetch all queries stored by this person.
      rclient.keys("query_#{ req.user._id.toString() }_*", (err, keys) ->
        rclient.mget keys, (err, values) ->
          # Group common queries together and sort by count.
          processed = []
          for value in values
            processed.push value.trim()
          results = _.groupBy(processed)
          set = []
          for query, number of results
            obj = {}
            obj[query] = number.length
            set.push(obj)
          set = _.sortBy set, (query) -> return _.values(query)[0]
          sortedSet = []
          for query in set
            sortedSet.push _.keys(query)[0]
          sortedSet = sortedSet.reverse()
          res.json sortedSet
      )

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
            fields: ['title', 'body'] # search the title and body of posts.
            default_operator: 'AND' # require all query terms to match
            query: req.params.query # The query from the REST call.
            use_dis_max: true
            fuzzy_prefix_length : 3
        filter:
          and: [
            {
              term:
                _user: req.user._id.toString()
            }
            #,
            #{
            #range:
              #created:
                #from: 1262304000000
                #to: 1293840000000
            #}
            ,
            {
              term:
                deleted: false
                draft: false
            }
          ]
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
        if err
          console.error err
          res.json 500, err
        else
          res.json posts
          # Record the query if there's a result.
          if posts?.hits.total > 0 and not err
            recordQuery(req.params.query, req.user._id.toString())
      )
  else
    res.redirect '/login'

# Listen on port 3000 or a passed-in port
args = process.argv.splice(2)
if args[0]? then port = parseInt(args[0], 10) else port = 3000
app.listen(port)
console.log("Express server listening on port %d in %s mode", port, app.settings.env)
