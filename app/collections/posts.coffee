{Post} = require 'models/post'
class exports.Posts extends Backbone.Collection

  url: '/posts'
  model: Post
  sync: Backbone.cachingSync(Backbone.sync, 'posts')

  initialize: ->
    @last_post = ""
    @loading(false)
    app.eventBus.on 'distance:bottom_page', ((distance) =>
      if distance <= 1500 then @load()
    ), @

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

  load: ->
    unless @isLoading
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
        cache_append: true
        data:
          created: created
        success: (collection, response) =>
          # If server returns nothing, this means we're at the bottom and should
          # stop trying to load new posts.
          if _.isString response
            app.eventBus.off null, null, @
            @loading(false)
            return
          # Backbone.cachesync returns junk sometimes.
          unless _.last(response)? then return
          # Set the posts collection last created time from the response.
          @new_last_post = _.last(response)['created']
          @last_post = @new_last_post if @new_last_post < @last_post or @last_post is ""
          @loading(false)
