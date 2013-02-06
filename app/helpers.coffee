Post = require 'models/post'

class exports.BrunchApplication
  constructor: ->
    _.defer =>
      @initialize()
      Backbone.history.start({ pushState: true })

  initialize: ->
    null

  util: ->

exports.loadPostModel = (id, nid = false) ->
  if nid
    if app.collections.posts.getByNid(id)
      return app.collections.posts.getByNid(id)
    else if app.collections.postsCache.getByNid(id)
      return app.collections.postsCache.getByNid(id)
    else
      post = new Post( nid: id, id: null )
      post.fetch( nid: id )
      app.collections.postsCache.add post
      return post
  else
    if app.collections.posts.get(id)
      return app.collections.posts.get(id)
    else
      post = new Post( id: id )
      post.fetch()
      app.collections.postsCache.add post
      return post

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
  throttled = _.throttle(currentPosition, 500)
  $(window).scroll(throttled)

exports.search = (query, callback) ->
  $.getJSON('/search/' + query, (data) -> callback(data))

# Misc global stuff
$ ->
  reportNearBottom = ->
    app.eventBus.trigger 'distance:bottom_page', ($(document).height() - $(window).height()) - $(window).scrollTop()
  throttled = _.throttle(reportNearBottom, 200)
  $(window).scroll(throttled)

exports.throbber = (classes="", size="16px") ->
      return '<span class="throbber ' + classes + '" style="height:' + size + ';width:' + size + ';">
              <div class="bar1"></div> <div class="bar2"></div> <div class="bar3"></div> <div class="bar4"></div> <div class="bar5"></div> <div class="bar6"></div> <div class="bar7"></div> <div class="bar8"></div> <div class="bar9"></div> <div class="bar10"></div> <div class="bar11"></div> <div class="bar12"></div>
              </span>'
