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

    if success then success(model, resp, options)
    model.trigger('sync', model, resp, options)

  error = options.error
  options.error = (xhr) ->
    if xhr.status is 0
      app.state.set('online', false)
      saveOfflineChanges(model, _.extend(params, options))
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

  key = "#{ burry.keys().length }::#{ options.type }::#{model.get('nid')}"
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
    model._operation = key.split('::')[1]
    model._key = key
    model._order = key.split('::')[0]

    operations.push model

  # If there was multiple operations done on the same post, merge those
  # operations together. We do this as if we create a post offline and then modify
  # it, that changes the post's NID to use a real one provided by the backend so we
  # wouldn't be able to apply any subsequent changes. To avoid this problem, we merge
  # operations together and post those all at once.
  #
  # If we ever start storing post revisions, we'll need to revisit this.
  operations = _.groupBy operations, (model) -> return model.nid
  operations = _.map operations, (modelGroup) ->
    # If there's multiple operations on a post, pick the ultimate operation.
    # DELETE trumps POST which trumps PUT which trumps PATCH
    if modelGroup.length > 1
      if 'PUT' in _.pluck(modelGroup, '_operation')
        winningOperation = "PUT"
      if 'POST' in _.pluck(modelGroup, '_operation')
        winningOperation = "POST"
      if 'DELETE' in _.pluck(modelGroup, '_operation')
        winningOperation = "DELETE"

    # Before merging all the operations, sort them by the order they were completed
    # so the latest of each edits are retained.
    modelGroup = _.sortBy modelGroup, (model) -> return parseInt model._order, 10
    model = _.extend.apply this, modelGroup
    model._order = null # Not needed anymore.

    if modelGroup.length > 1
      model._operation = winningOperation

    return model

  removeOperationOnSuccess = (key) ->
    for id in burry.keys()
      if _.str.contains id, key.split('::')[2]
        burry.remove(id)

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
        app.collections.posts.burry.remove(key.split('::')[2])

        # If this post is being edited right now, save that model.
        if app.models.editing?.get('nid') is model.nid
          # Delete our temporary IDs so that model.save will still create the model
          # on the server.
          app.models.editing.id = null
          app.models.editing.unset('nid')
          promise = app.models.editing.save()
          do (key, promise) ->
            promise.done -> removeOperationOnSuccess(key)
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
            promise.done -> removeOperationOnSuccess(key)
        else
          # Delete our temporary IDs so that model.save will still create the model
          # on the server.
          model.id = null
          model.nid = null
          do (key, model) ->
            newModel = app.collections.posts.create model
            newModel.once('sync', -> removeOperationOnSuccess(key))

      # Grab the post model and update and save it.
      when "PUT"
        if app.collections.posts.getByNid(model.nid)?
          do (key, model) ->
            promise = app.collections.posts.getByNid(model.nid).set(model).save()
            promise.done -> removeOperationOnSuccess(key)
        else
          do (key, model) ->
            realModel = app.util.loadPostModel(model.nid, true)
            realModel.once('sync', ->
              promise = realModel.set(model).save()
              promise.done -> removeOperationOnSuccess(key)
            )

      # Find the post model and delete it.
      when "DELETE"
        # If the model is in the posts collection, delete it immediatly.
        if app.collections.posts.getByNid(model.nid)?
          app.collections.posts.getByNid(model.nid).destroy()
        # Else load it off the server and then destroy it.
        else
          do (key, model) ->
            realModel = app.util.loadPostModel(model.nid, true)
            realModel.once('sync', ->
              if realModel.destroy?
                promise = realModel.destroy()
                promise.done -> removeOperationOnSuccess(key)
            )
