{Post} = require 'models/post'
class exports.Posts extends Backbone.Collection

  url: '/posts'
  model: Post

  initialize: ->
    @last_id = ""
    @loading(false)
    app.eventBus.on 'distance:bottom_page', (distance) =>
      if distance <= 1500 then @load()

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

      if @last_id is ""
        created = new Date().toJSON()
      else
        created = @get(@last_id).get('created')
      @fetch
        add: true
        data:
          created: created
        success: (collection, response) =>
          # Set the posts collection last_id from the response.
          @last_id = _.last(response)['id']
          @loading(false)
