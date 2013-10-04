module.exports = (req, res, next) ->
  if req.accepted[0].value is 'text/html'
    # Ignore login/logout paths.
    if req.path in ["/login", "/logout"]
      next()
    # Otherwise render index.
    else
      res.render 'index'
  else
    next()
