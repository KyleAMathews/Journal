module.exports = (req, res, next) ->
  if req.accepted[0]?.value is 'text/html'
    # Ignore login/logout paths.
    if req.path in ["/login", "/logout"]
      next()
    # Otherwise render index.
    else
      # TODO this his hacky, replace with real environment variable system.
      unless process.platform is "darwin" or process.env.NODE_ENV is "development" # e.g. we're on a mac so developing.
        res.render 'index', manifest: '/appcache.appcache'
      else
        res.render 'index'
  else
    next()
