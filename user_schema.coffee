config = require './app_config'
bcrypt = require 'bcrypt'

# dependencies for authentication
Passport = require('passport')
LocalStrategy = require('passport-local').Strategy;

# Setup MongoDB connection.
mongoose = require('mongoose')
mongoose.connect(config.mongo_url)

# Setup MongoDB schemas.
Schema = mongoose.Schema

toLower = (v) ->
  return v.toLowerCase()

UserSchema = new Schema (
  name: String
  email: { type: String, unique: true, set: toLower }
  password: String
  created: Date
  changed: { type: Date, index: true }
)

UserSchema.methods.setPassword = (password, done) ->
  console.log 'inside setPassword'
  bcrypt.genSalt 10, (err, salt) =>
    bcrypt.hash password, salt, (err, hash) =>
      console.log 'hash ', hash
      @password = hash
      done()

UserSchema.methods.verifyPassword = (password, callback) ->
  console.log @
  bcrypt.compare(password, @password, callback);

UserSchema.statics.authenticate = (email, password, callback) ->
  console.log 'email', email
  email = toLower(email)
  failMessage = "Your email or password was not correct."
  @findOne { email: email }, (err, user) ->
    if err then return callback err
    if not user then return callback null, false, { message: failMessage }
    user.verifyPassword password, (err, passwordCorrect) ->
      if err then return callback err
      if not passwordCorrect then return callback null, false, { message: failMessage }
      # Successful authentication!
      callback null, user

# Define local strategy for Passport
mongoose.model 'user', UserSchema
User = mongoose.model 'user'
Passport.use new LocalStrategy usernameField: 'email', (email, password, done) ->
  console.log 'inside something'
  console.log User
  User.authenticate email, password, (err, user, message) ->
    if err then console.err err
    return done(err, user, message)

# serialize user on login
Passport.serializeUser (user, done) ->
  done(null, user.id)

# deserialize user on logout
Passport.deserializeUser (id, done) ->
  User.findById id, (err, user) ->
    done(err, user)
