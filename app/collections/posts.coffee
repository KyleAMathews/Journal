Post = require 'models/post'
class exports.Posts extends Backbone.Collection

  url: '/posts'
  model: Post
  sync: Backbone.cachingSync(Backbone.sync, 'posts', null, true)

  initialize: ->
    @last_post = ""
    @loading(false)
    @on 'set_cache_ids', @setCacheIds
    @postsViewActive = false
    @setMaxOldPostFromCollection = _.once =>
      @maxOld = @max((post) -> return moment(post.get('created')).unix())

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

  load: (override = false) ->
    if not @isLoading or override
      @loading(true)
      # Timeout request after 10 seconds
      setTimeout =>
        if @isLoading then @loading(false); @load()
      , 10000

      if @last_post is ""
        created = new Date().toJSON()
      else
        created = @last_post

      @fetch
        update: true
        remove: false
        data:
          created: created
        success: (collection, response, options) =>
          # If server returns nothing, this means we're at the bottom and should
          # stop trying to load new posts.
          if _.isString response
            app.eventBus.off null, null, @
            @loading(false)
            return

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

          # Backbone.cachesync returns junk sometimes.
          unless _.last(response)? then return
          # Set the posts collection last created time from the response.
          @new_last_post = _.last(response)['created']
          @last_post = @new_last_post if @new_last_post < @last_post or @last_post is ""
          @loading(false)
          _.defer =>
            @setCacheIds()

  setCacheIds: ->
    @burry.set('__ids__', _.pluck(@first(10), 'id'))
