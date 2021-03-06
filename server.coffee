config = require './app_config'

express = require 'express'
passport = require 'passport'
MemoryStore = express.session.MemoryStore
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

# Require routes
attachment = require './routes/attachment'
post = require './routes/post'
search = require './routes/search'
sessions = require './routes/session_management'

app = express()

# Assign views to use the ECT templating language.
ECT = require('ect')
ectRenderer = ECT({
  watch: true
  root: __dirname + '/views'
})
app.engine('ect', ectRenderer.render)

# Setup Express middleware.
app.configure ->
  app.set 'view engine', 'ect'
  app.set 'views', __dirname + '/views'
  app.use express.compress()
  app.use express.static 'public'
  app.use express.cookieParser()
  app.use express.responseTime()
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use express.session({ store: new MemoryStore(), secret: 'Make Stuff', cookie: { maxAge: 1209600000 }}) # two weeks
  app.use passport.initialize()
  app.use passport.session()
  app.use flash()
  app.use require './middleware/set_vars_on_locals'
  app.use require './middleware/require_login'
  app.use require './middleware/detect_html_request'
  app.use app.router

# Sessions.
app.get '/ping', sessions.ping
app.get '/login', sessions.login
app.post '/login', passport.authenticate('local',
  {
    successRedirect: '/'
    failureRedirect: '/login'
    failureFlash: true
  })
app.get '/logout', sessions.logout

# Posts.
app.get '/node/:nid', post.getNidPost
app.get '/posts', post.list
app.post '/posts', post.post
app.put '/posts/:id', post.put
app.del '/posts/:id', post.delete
app.get '/posts/:id', post.getPost

# Attachments
app.post '/attachments', attachment.post
app.get '/attachments/:id', attachment.getSmall
app.get '/attachments/:id/original', attachment.getOriginal

# Search
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
