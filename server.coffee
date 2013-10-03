config = require './app_config'

express = require 'express'
mongoose = require 'mongoose'
passport = require 'passport'
RedisStore = require('connect-redis')(express)
redis = require 'redis'
require './user_schema'
require './post_schema'
async = require 'async'
flash = require 'connect-flash'
_ = require 'underscore'
# Import Underscore.string to separate object, because there are conflict functions (include, reverse, contains)
_.str = require('underscore.string')
# Mix in non-conflict functions to Underscore namespace if you want
_.mixin(_.str.exports())

app = express()

# Require routes
attachment = require './routes/attachment'
post = require './routes/post'
search = require './routes/search'

# Setup redis client
rclient = redis.createClient(config.redis_url.port, config.redis_url.hostname, {auth_pass: config.redis_url.pass})

if config.redis_url.pass
  rclient.auth(config.redis_url.pass, (err) ->
    if (err)
      throw err
  )

# Setup RedisStore for sessions
sessionStore = new RedisStore({
  client: rclient
})

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

# Posts.
app.get '/node/:nid', post.getNidPost
app.get '/node/:nid/edit', post.getNidPostEdit
app.get '/posts', post.list
app.post '/posts', post.post
app.put '/posts/:id', post.put
app.del '/posts/:id', post.delete
app.get '/posts/:id', post.getPost
app.get '/posts/new', post.newPost

# Attachments
app.post '/attachments', attachment.post
app.get '/attachments/:id', attachment.getSmall
app.get '/attachments/:id/original', attachment.getOriginal

# Search
app.get '/search', search.getIndex
app.get '/search/queries', search.getQueries
app.get '/search/:query', search.makeQuery

# TODO make admin section where its easy to create new users.
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

# Listen on port 3000 or a passed-in port
args = process.argv.splice(2)
if args[0]? then port = parseInt(args[0], 10) else port = 3000
app.listen(port)
console.log("Express server listening on port %d in %s mode", port, app.settings.env)
