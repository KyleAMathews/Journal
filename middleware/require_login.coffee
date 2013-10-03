module.exports = (req, res, next) ->
  # No redirect loops yo.
  if req.path is "/login"
    next()
  # User is authenticated, carry on.
  else if req.isAuthenticated()
    next()
  # They're not authenticated, figure out what to send back to them.
  # This is an HTML request, send to login.
  else if req.accepted[0].value is 'text/html'
    res.redirect '/login'
  # This is a request for... something else. Probably JSON. Return a 401.
  else
    res.send(401)
