class exports.BrunchApplication
  constructor: ->
    $ =>
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
