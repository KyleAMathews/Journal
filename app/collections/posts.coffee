Post = require 'models/post'
class exports.Posts extends Backbone.Collection

  url: '/posts'
  model: Post

  initialize: ->
    @lastPost = ""
    @timesLoaded = 0
    @loading(false)
    @on 'set_cache_ids', @setCacheIds
    @postsViewActive = false
    @setMaxOldPostFromCollection = _.once =>
      @maxOld = @max((post) -> return moment(post.get('created')).unix())

    # Try loading posts from localstorage.
    @burry = new Burry.Store('posts')
    if @burry.get('__ids__')?
      @loadFromCache()

    app.eventBus.on 'visibilitychange', (state) =>
      if state is "visible"
        # Calculate time since last fetch.
        if moment().diff(moment(@lastFetch), 'minutes') > 15
          @loadChangesSinceLastFetch()

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

  # Load all posts (newer than our oldest post) created or changed since the last fetch.
  loadChangesSinceLastFetch: ->
    @fetch
      update: true
      remove: false
      data:
        changed: @lastFetch
        oldest: @lastPost
      success: (collection, response, options) =>
        # Record fetch time.
        @lastFetch = new Date().toJSON()

        # See if the collection needs reset as there's a new post.
        @resetCollection(response)

  load: (override = false) ->
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

          # Cache all posts by nid.
          for post in @models
            @cachePost(post)

          _.defer =>
            @setCacheIds()

  resetCollection: (response) ->
    # If the server returns a post that's newer than any already displayed,
    # trigger reset on the collection so postViews re-renders.
    @setMaxOldPostFromCollection()
    maxNew = _.max(response, (post) -> return moment(post.created).unix())
    if @maxOld? and maxNew? and @maxOld.get('created') < maxNew.created
      @maxOld = @first()
      # Seems we need to wait a bit to let the new post(s) to be added to the collection
      # to ensure they'll be rendered.
      _.defer =>
        @trigger 'reset'

  setCacheIds: ->
    posts = @first(10)
    nids = (post.get('nid') for post in posts)
    @burry.set('__ids__', nids)

  cachePost: (post) ->
    @burry.set "posts_pid_#{ post.get('nid') }", post.toJSON()

  loadFromCache: ->
    postsIds = @burry.get '__ids__'
    posts = []
    for nid in postsIds
      post = @loadNidFromCache(nid)
      if post?
        posts.push post

    @reset posts
    @setMaxOldPostFromCollection()

  loadNidFromCache: (nid) ->
    return @burry.get "posts_pid_#{ nid }"
