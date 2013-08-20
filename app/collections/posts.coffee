Post = require 'models/post'
class exports.Posts extends Backbone.Collection

  url: '/posts'
  model: Post

  initialize: ->
    @currentScrollModel = 0
    @lastPost = ""
    @timesLoaded = 0
    @loading(false)
    @postsViewActive = false
    @setMaxNewPostFromCollection = =>
      @maxNew = @max((post) -> return moment(post.get('created')).unix())

    # Remove post from cache when it's removed from the collection.
    @on 'add remove', (model) ->
      @setCacheIds()
      @burry.remove(model.get('nid'))

    # Try loading posts from localstorage with a default TTL of three weeks.
    @burry = new Burry.Store('posts', 30240)
    if @burry.get('__ids__')?
      @loadFromCache()

    app.eventBus.on 'visibilitychange', (state) =>
      if state is "visible"
        # Calculate time since last fetch.
        if moment().diff(moment(@lastFetch), 'minutes') > 15
          @loadChangesSinceLastFetch()

    # Load drafts
    @fetchDrafts()

  getPosts: ->
    @filter (post) ->
      post.get('draft') is false

  getDrafts: ->
    @filter (post) ->
      post.get('draft') is true

  getByNid: (nid) ->
    nid = parseInt(nid, 10)
    return @find (post) -> post.get('nid') is nid

  comparator: (model, model2) ->
    if model.get('created') is model2.get('created') then return 0
    if model.get('created') < model2.get('created') then return 1 else return -1

  loading: (isLoading) ->
    if isLoading
      @trigger 'loading-posts'
      @isLoading = true
    if not isLoading
      @trigger 'done-loading-posts'
      @isLoading = false

  fetchErrorHandler: (models, xhr) =>
    @loading(false)
    if xhr.status is 0
      app.state.set('online', false)
    else if xhr.status is 401
      window.location = "/login"

  # Load all posts (newer than our oldest post) created or changed since the last fetch.
  loadChangesSinceLastFetch: ->
    # If we're offline, return.
    unless app.state.isOnline() then return

    @fetch
      update: true
      remove: false
      data:
        changed: @lastFetch
        oldest: @lastPost
      error: @fetchErrorHandler
      success: (collection, response, options) =>
        # Record fetch time.
        @lastFetch = new Date().toJSON()

        # See if the collection needs reset as there's a new post.
        @resetCollection(response)

  load: (override = false) ->
    # If we're offline, return.
    unless app.state.isOnline() then return

    # We've already loaded everything.
    if @loadedAllThePosts then return

    if not @isLoading or override
      @loading(true)
      # Timeout request after 10 seconds
      setTimeout =>
        if @isLoading then @loading(false); @load()
      , 10000

      if @lastPost is ""
        created = new Date().toJSON()
      else
        created = @lastPost

      @fetch
        update: true
        remove: false
        data:
          created: created
        error: @fetchErrorHandler
        success: (collection, response, options) =>
          # Record fetch time.
          @lastFetch = new Date().toJSON()

          # If server returns nothing, this means we're at the bottom and should
          # stop trying to load new posts.
          if _.isString response
            @loadedAllThePosts = true
            @loading(false)
            return

          # See if the collection needs reset as there's a new post.
          @resetCollection(response)

          # Set the posts collection last created time from the response.
          @newLastPost = _.last(response)['created']
          @lastPost = @newLastPost if @newLastPost < @lastPost or @lastPost is ""

          # We're not done loading until the server responds.
          @loading(false)

          # Cache all posts by nid unless there are local changes that are more recent.
          for post in @models
            # There's offline changes. Replace what we loaded from the server
            # with the local changes.
            if @burry.get(post.get('nid'))?.changed > post.get('changed')
              console.log @burry.get(post.get('nid'))
              console.log post.toJSON()
              @get(post.id).set(@burry.get(post.get('nid')))
            else
              @cachePost(post)

          _.defer =>
            @setCacheIds()

          # Update
          @setMaxNewPostFromCollection()

  resetCollection: (response) ->
    # If the server returns a post that's newer than any already displayed,
    # trigger reset on the collection so postViews re-renders.
    maxNew = _.max(response, (post) -> return moment(post.created).unix())
    if @maxNew? and _.isObject(@maxNew) and maxNew? and @maxNew.get('created') < maxNew.created
      @maxNew = @first()
      # Seems we need to wait a bit to let the new post(s) to be added to the collection
      # to ensure they'll be rendered.
      _.defer =>
        @trigger 'reset'

  setCacheIds: ->
    posts = @getPosts().slice(0, 10)
    nids = (post.get('nid') for post in posts)
    @burry.set('__ids__', nids)

  cachePost: (post) ->
    @burry.set post.get('nid'), post.toJSON()

  loadFromCache: ->
    postsIds = @burry.get '__ids__'
    posts = []
    for nid in postsIds
      if nid is null then continue
      post = @loadNidFromCache(nid)
      if post?
        posts.push post

    @reset posts
    @setMaxNewPostFromCollection()

  loadNidFromCache: (nid) ->
    return @burry.get nid

  posNext: ->
    model = @at(@currentScrollModel + 1)
    if model?
      @currentScrollModel = @currentScrollModel + 1
      return model.position()
    else
      return undefined

  posPrev: ->
    model = @at(@currentScrollModel - 1)
    if model?
      @currentScrollModel = @currentScrollModel - 1
      return model.position()
    else
      return undefined

  fetchDrafts: ->
    unless app.state.isOnline() then return

    $.getJSON('/posts?draft=true', (drafts) =>
      @add drafts
      @trigger 'sync:drafts'
    )
