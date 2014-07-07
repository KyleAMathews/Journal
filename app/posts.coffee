request = require 'superagent'
Backbone = require 'backbone'
_ = require 'underscore'
moment = require 'moment'
eventBus = require './event_bus'

# Backbone collection and some handy methods.
window.posts = posts = new Backbone.Collection()
console.log eventBus
posts.on 'change add remove', -> eventBus.trigger('postsChange')
posts.comparator = (post1, post2) ->
  if post1.get('created_at') > post2.get('created_at')
    -1
  else
    1

posts.filteredPosts = ->
  @filter (post) ->
    return not post.get('deleted') or post.get('unsaved')

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
        console.timeEnd('fetch posts')
        if _.isFunction callback
          callback()
        if initialFetch
          posts.reset res.body
          replaceLocalStorageCache(res.body)
        else
          posts.add res.body

# Immediately do an initial fetch from server.
fetchMore(true)

postsDAO = {}

replaceLocalStorageCache = (posts) ->
  localStorage.setItem('posts_cache', JSON.stringify(posts))

addToLocalStorageCache = (posts) ->
  cache = JSON.parse(localStorage.getItem('posts_cache'))
  posts = cache.concat posts
  localStorage.setItem('posts_cache', JSON.stringify(posts))

postsDAO.getPosts = (number) ->
  return posts.filteredPosts().slice(0, number)

postsDAO.nextPage = (options, callback) ->
  defaults =
    offset: 0
    limit: 15
  options = _.extend defaults, options

  slice = posts.filteredPosts().slice 0, options.offset + options.limit
  if slice.length is options.offset + options.limit
    callback slice
  else if slice.length < options.offset + options.limit
    fetchMore null, ->
      callback posts.filteredPosts().slice 0, options.offset + options.limit

postsDAO.getPost = (id, callback) ->
  # Check local or get from server
  if posts.get(id)?
    callback null, posts.get(id).toJSON()
  else
    request
      .get("/posts/#{id}")
      .set('Accept', 'application/json')
      .end (err, res) =>
        if res.status isnt 200
          callback(res.status, res.body)
        else
          callback(null, res.body)

addPostToDirtyArray = (post) ->
  # Add post to dirty-array until the server confirms it's saved.
  try
    dirtyArray = JSON.parse localStorage.getItem('dirty-posts')
  catch
    console.log 'bad json'

  unless _.isArray dirtyArray then dirtyArray = []
  dirtyArray.push post
  console.log dirtyArray
  localStorage.setItem('dirty-posts', JSON.stringify(dirtyArray))

removeUnsavedPost = (id) ->
  posts.remove(posts.get(id))
  try
    dirtyArray = JSON.parse localStorage.getItem('dirty-posts')
  catch
    console.log 'bad json'
  unless _.isArray dirtyArray then dirtyArray = []
  dirtyArray = _.filter dirtyArray, (post) -> post.id isnt id
  localStorage.setItem('dirty-posts', JSON.stringify(dirtyArray))

postsDAO.savePost = (post, callback) ->
  if post.unsaved?
    addPostToDirtyArray(post)

  # Attempt to persist
  post.updated_at = new Date().toJSON()

  console.log post
  if post.unsaved
    delete post.unsaved
    tempId = post.id
    delete post.id
    request
      .post("/posts")
      .set('Accept', 'application/json')
      .send(post)
      .end (err, res) =>
        if res.status is 201
          removeUnsavedPost(tempId)
          addToLocalStorageCache([res.body])
          posts.add [res.body]
          callback(null, res.body)
        else
          callback(res.status, res.body)
  else
    request
      .patch("/posts/#{post.id}")
      .set('Accept', 'application/json')
      .send(post)
      .end (err, res) =>
        if res.status is 200
          posts.add [res.body], merge: true
          callback(null, res.body)
        else
          callback(res.status, res.body)

postsDAO.createDraft = ->
  id = uuid.v1()
  newPost =
    created_at: new Date().toJSON()
    updated_at: new Date().toJSON()
    unsaved: true
    id: id

  posts.add newPost

  return id

module.exports = postsDAO
