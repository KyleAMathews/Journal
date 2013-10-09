# Map from CRUD to HTTP for our default `Backbone.sync` implementation.
methodMap =
  'create': 'POST',
  'update': 'PUT',
  'patch':  'PATCH',
  'delete': 'DELETE',
  'read':   'GET'

# Local storage.
window.offline_changes = burry = new Burry.Store('offline_changes')

# Persist changes made while the app is offline to localstorage so these changes
# can be replyed when we come back online.
Backbone.sync = (method, model, options = {}) ->
  type = methodMap[method]

  # Default JSON-request options.
  params = {type: type, dataType: 'json'}

  # Ensure that we have a URL.
  unless options.url
    params.url = _.result(model, 'url') || urlError()

  # Ensure that we have the appropriate request data.
  if not options.data? and model and (method is 'create' or method is 'update' or method is 'patch')
    params.contentType = 'application/json'
    params.data = JSON.stringify(options.attrs || model.toJSON(options))

  # Don't process data on a non-GET request.
  if params.type isnt 'GET'
    params.processData = false

  success = options.success
  options.success = (resp) ->
    # A successful Ajax request means we're online.
    app.state.set('online', true)

    if success then success(resp)
    model.trigger('sync', model, resp, options)

  error = options.error
  options.error = (xhr) ->
    if xhr.status is 404
      saveOfflineChanges(model, _.extend(params, options))
      app.state.set('online', false)
    # The user isn't logged in. Redirect to login page.
    else if xhr.status is 401
      window.location = "/login"
    if error then error(model, xhr, options)
    model.trigger('error', model, xhr, options)

  # if we're online (or we don't know yet), do normal sync.
  if app.state.isOnline()
    if params.type in ['POST', 'PUT', 'PATCH']
      # Persist changes locally.
      @saveLocal()

    # Make the request, allowing the user to override any Ajax options.
    xhr = options.xhr = Backbone.ajax(_.extend(params, options))
    model.trigger('request', model, xhr, options)
    return xhr
  else
    saveOfflineChanges(model, _.extend(params, options))
    # Simulate success.
    if success then success(model, { status: 200 }, options)
    model.trigger('sync', model, { status: 200 }, options)

getKeyByNid = (nid) ->
  return _.find burry.keys(), (key) -> return key.split("::")[1] is String(nid)

saveOfflineChanges = (model, options) ->
  # No changes to save.
  if options.type is "GET" then return
  # Only save posts for now.
  unless model.constructor.name is 'Post' then return

  # Ensure there's a created date.
  unless model.get('created')?
    model.set('created', new Date().toJSON())

  model.set('changed', new Date().toJSON())

  # Ensure there's an ID and NID.
  unless model.id then model.id = "OFFLINE_#{ Math.round(Math.random() * 10000000000) }"
  unless model.get('nid') then model.set('nid', Math.round(Math.random() * 10000000000) + 1000000) # If someone ever writes more than 1 million posts, we might have to change this.

  # Check if this model already has been edited since app went offline.
  # If it has, merge new changes with the old ones. If not, add the model.
  key = getKeyByNid(model.get('nid'))
  if key?
    # Merge new operations into older ones based on the following algorithm.
    #
    oldOperation = key.split("::")[0]
    newOperation = options.type
    console.log newOperation, oldOperation
    # DELETEs after a POST should just remove everything.
    if newOperation is "DELETE" and oldOperation is "POST"
      return burry.remove(key)
    # DELETEs after a PUT should override that operation.
    if newOperation is "DELETE" and oldOperation is "PUT"
      burry.remove(key)
      key = "DELETE::#{ model.get('nid') }"
    # PUTs after a POST just should overwrite the POST (but leave the operation as POST).
    # PUTs after a PUT should just overwrite previous PUT.
  # Else this model hasn't been touched previously offline and we need to create
  # a new key.
  else
    key = "#{ options.type }::#{model.get('nid')}"

  burry.set(key, model.toJSON())

app.state.on 'change:online', (model, online) ->
  if online and burry.keys().length > 0
    replayChanges()

# Replay operations performed by the user offline so to persist them to the server.
window.replayChanges = ->
  unless app.state.isOnline() then return

  operations = []
  for key in burry.keys()
    model = burry.get(key)
    model._operation = key.split('::')[0]
    model._key = key

    operations.push model

  for model in operations
    operation = model._operation
    key = model._key
    model._operation = null
    model._key = null


    switch operation
      when "POST"
        # Save the post to the server. If the post model is still in memory, use
        # that.
        # Delete temp version of post from the Posts collection cache.
        app.collections.posts.burry.remove(key.split('::')[1])

        # If this post is being edited right now, save that model.
        if app.models.editing?.get('nid') is model.nid
          # Delete our temporary IDs so that model.save will still create the model
          # on the server.
          app.models.editing.id = null
          app.models.editing.unset('nid')
          promise = app.models.editing.save()
          do (key, promise) ->
            promise.done -> burry.remove(key)
        # Else if the post is in the posts collection (which it will be if we've
        # saved it already offline), save that model.
        else if app.collections.posts.getByNid(model.nid)?
          # Delete our temporary IDs so that model.save will still create the model
          # on the server.
          model = app.collections.posts.getByNid(model.nid)
          model.id = null
          model.unset('nid')
          # Ensure post is added to cached list of most recent posts so it shows
          # up right away on refreshing the app.
          model.once 'sync', -> app.collections.posts.setCacheIds()
          do (key, model) ->
            promise = model.save()
            promise.done -> burry.remove(key)
        # Else it's not in memory (this shouldn't normally happen) so just create and save post.
        else
          # Delete our temporary IDs so that model.save will still create the model
          # on the server.
          model.id = null
          model.nid = null
          do (key, model) ->
            newModel = app.collections.posts.create model
            newModel.once('sync', -> burry.remove(key))

      # Grab the post model and update and save it.
      when "PUT"
        if app.collections.posts.getByNid(model.nid)? # It's already in memory.
          do (key, model) ->
            promise = app.collections.posts.getByNid(model.nid).set(model).save()
            promise.done -> burry.remove(key)
        else
          do (key, model) ->
            realModel = app.util.loadPostModel(model.nid, true) # Load from server.
            promise = realModel.fetch()
            promise.done ->
              promise = realModel.set(model).save()
              promise.done -> burry.remove(key)

      # Find the post model and delete it.
      when "DELETE"
        # If the model is in the posts collection, delete it immediately.
        if app.collections.posts.getByNid(model.nid)?
          app.collections.posts.getByNid(model.nid).destroy()
        # Else load it off the server and then destroy it.
        else
          do (key, model) ->
            realModel = app.util.loadPostModel(model.nid, true)
            realModel.once('sync', ->
              if realModel.destroy?
                promise = realModel.destroy()
                promise.done -> burry.remove(key)
            )
