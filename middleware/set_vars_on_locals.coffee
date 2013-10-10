_ = require 'underscore'

module.exports = (req, res, next) ->
  if req.user?.name?
    user = JSON.parse(JSON.stringify(req.user))
    res.locals.currentuser = _.omit(user, 'password')
  else
    app.locals.currentuser = {}
    app.locals.currentuser.name = "Login to your"
  next()
