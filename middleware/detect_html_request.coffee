module.exports = (req, res, next) ->
  if req.accepted[0].value is 'text/html'
    res.render 'index'
  else
    next()
