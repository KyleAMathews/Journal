# Simple ping route so client can detect if it's online or not.
exports.ping = (req, res) ->
  if req.isAuthenticated()
    res.send(200)
  else
    res.send(401)

exports.ping = (req, res) ->
  if req.isAuthenticated()
    res.send(200)
  else
    res.send(401)

exports.login = (req, res) ->
  unless req.isAuthenticated()
    json =
      errorMessages: []
    messages = req.flash()
    if messages.error?
      json.errorMessages = messages.error
    res.render 'login', json
  else
    res.redirect '/'

exports.logout = (req, res) ->
  req.logout()
  res.redirect '/login'
