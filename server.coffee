express = require 'express'
mongoose = require 'mongoose'
require './post_schema'

app = express.createServer()

# Setup Express middleware.
app.configure ->
  app.set 'views', __dirname + '/views'
  app.set 'view engine', 'jade'
  app.use express.cookieParser()
  app.use express.responseTime()
  app.use express.bodyParser()
  app.use express.methodOverride()
  #app.use express.session({ store: new RedisStore, secret: 'Make Stuff', cookie: { maxAge: 1209600000 }}) # two weeks
  app.use app.router
  app.use express.static __dirname + '/public'

app.get '/', (req, res) ->
  res.render 'index'

app.get '/posts', (req, res) ->
  Post = mongoose.model 'post'
  Post.find()
    .limit(50)
    .desc('created')
    .run (err, posts) ->
      console.log 'query done'
      unless err or not posts?
        for post in posts
          post.setValue('id', post.getValue('_id'))
        res.json posts
      else
        res.json 'found nothing'
app.post '/posts', (req, res) ->
  res.send 'hello world'
app.put '/posts/:id', (req, res) ->
  res.send 'hello world'
app.del '/posts/:id', (req, res) ->
  res.send 'hello world'

# Listen on port 3000 or a passed-in port
args = process.argv.splice(2)
if args[0]? then port = parseInt(args[0], 10) else port = 3000
app.listen(port)
console.log("Express server listening on port %d in %s mode", app.address().port, app.settings.env)


# Read in info from mysql and add each result to mongodb
#ghm = require("github-flavored-markdown")
#mysql = require('mysql')
#DATABASE = 'drupal7_beta1'
#TABLE = 'node'
#client = mysql.createClient(
  #user: 'user'
  #password: 'password'
#)

#client.query('USE '+DATABASE)

#count = 0
#client.query(
  #'SELECT n.title,
  #r.body_value AS body,
  #n.created,
  #n.changed
  #FROM node n
  #INNER JOIN field_data_body r
  #WHERE n.vid = r.revision_id',
  #(err, results, fields) ->
    #if err
      #throw err

    #Post = mongoose.model 'post'
    #for result in results
      #console.log 'saving ', result.title
      #action = new Post()
      #action.title = result.title
      #action.body = result.body
      #d_created = new Date()
      #d_changed = new Date()
      #d_created.setTime(result.created * 1000)
      #d_changed.setTime(result.changed * 1000)
      #action.created = d_created.toISOString()
      #action.changed = d_changed.toISOString()
      #action.save (err) ->
        #if err then console.err err
        #count += 1

    #console.log 'done saving to mongo'
    #console.log 'saved ', count
    #client.end()
#)
