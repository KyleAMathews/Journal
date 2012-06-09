class exports.BrunchApplication
  constructor: ->
    _.defer =>
      @initialize this
      Backbone.history.start({ pushState: true })

  initialize: ->
    null

exports.loadPost = (id, nid = false, callback) ->
  if _.isFunction nid
    callback = nid
    nid = false

  if nid
    if app.collections.posts.getByNid(id)
      callback app.collections.posts.getByNid(id)
    else
      app.collections.posts.fetch
        add: true
        data:
          nid: id
        success: (collection, response) =>
          callback collection.getByNid(id)
  else
    if app.collections.posts.get(id)
      callback app.collections.posts.get(id)
    else
      app.collections.posts.fetch
        add: true
        data:
          id: id
        success: (collection, response) =>
          callback collection.get(id)

exports.clickHandler = (e) ->
  # If the click target isn't a link, then return
  unless e.target.tagName is 'A' and $(e.target).attr('href')? then return
  # If the clicked link is "/logout" then let it continue
  if _.include ['/logout'], $(e.target).attr('href')
    return
  unless $(e.target).attr('href').indexOf('http') is 0
    # Prevent click from reloading page.
    e.preventDefault()
    href = $(e.target).attr('href')
    app.router.navigate(href, {trigger: true})

exports.scrollPosition = ->
  currentPosition = ->
    if window.location.pathname is '/'
      app.site.set postsScroll: $(window).scrollTop()
  throttled = _.throttle(currentPosition, 100)
  $(window).scroll(throttled)
