request = require 'superagent'
Backbone = require 'backbone'
_ = require 'underscore'
moment = require 'moment'

window.posts = posts = new Backbone.Collection()

fetchMore = (initialFetch = false, callback) ->
  console.time('fetch posts')

  if posts.last()?
    start = posts.last().get('created_at')
    start = moment(start).subtract('seconds', 1).toJSON()
  else
    start = new Date().toJSON()

  request
    .get('/posts')
    .set('Accept', 'application/json')
    .query(limit: 100)
    .query(start: start)
    .end (err, res) =>
      unless err
        posts.add res.body
        console.timeEnd('fetch posts')
        if _.isFunction callback
          callback()
        if initialFetch
          localStorage.setItem('posts_cache', JSON.stringify(res.body))

# Immediately do an initial fetch from server.
fetchMore(true)

# Immediately add posts from localStorage.
console.time 'localstorage fetch'
posts.add JSON.parse(localStorage.getItem('posts_cache'))
console.timeEnd 'localstorage fetch'

postsDAO = {}

postsDAO.nextPage = (options, callback) ->
  defaults =
    offset: 0
    limit: 15
  options = _.extend defaults, options

  slice = posts.slice options.offset, options.offset + options.limit
  if slice.length is options.limit
    callback slice
  else if slice.length < options.limit
    fetchMore null, ->
      callback posts.slice options.offset, options.offset + options.limit

postsDAO.getPost = (id, callback) ->
  # Check local or get from server
  if posts.get(id)?
    callback posts.get(id).toJSON()
  else
    request
      .get("/posts/#{id}")
      .set('Accept', 'application/json')
      .end (err, res) =>
        callback(res.body)


module.exports = postsDAO
