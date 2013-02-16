Post = require 'models/post'
class exports.Posts extends Backbone.Collection

  url: '/posts'
  model: Post
  sync: Backbone.cachingSync(Backbone.sync, 'posts', null, true)

  initialize: ->
    @lastPost = ""
    @timesLoaded = 0
    @loading(false)
    @on 'set_cache_ids', @setCacheIds
    @postsViewActive = false
    @setMaxOldPostFromCollection = _.once =>
      @maxOld = @max((post) -> return moment(post.get('created')).unix())

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
          @timesLoaded += 1

          # Backbone.cachingSync always returns the first 10 posts.
          if response[0].id is @first().id
            fromCache = true

          # Backbone.cacheSync returns junk sometimes.
          unless _.last(response)? then return

          # Record fetch time.
          @lastFetch = new Date().toJSON()

          # If server returns nothing, this means we're at the bottom and should
          # stop trying to load new posts.
          if _.isString response
            app.eventBus.off null, null, @
            @loading(false)
            return

          # See if the collection needs reset as there's a new post.
          @resetCollection(response)

          # Set the posts collection last created time from the response.
          @newLastPost = _.last(response)['created']
          @lastPost = @newLastPost if @newLastPost < @lastPost or @lastPost is ""

          # We're not done loading until the server responds.
          unless fromCache
            @loading(false)

          # Special case as our hacky way of detecting if the response is from
          # localstorage fails on the first load.
          if @timesLoaded is 2
            @loading(false)

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
    @burry.set('__ids__', _.pluck(@first(10), 'id'))
