# TODO
#
# make the site offline state checking smarter (e.g. check for changes to navigation.onLine and
# do an automatic backoff of how soon I'll check if we're online again and
# show that up top ala gmail—go to max of 3 minutes perhaps and let people
# check manually).
#
# Remove drafts
#
# create the new post with current draft logic with draft flas set to true (and scrub draft posts from elasticsearch results).
# run an update script which converts all drafts into posts w/ flag set to true
# Change drafts api call to get all models with draft set to true and regular
# POSTS get should ignore draft models.
#
# Load still unsaved new posts so when reloading the app so can load and edit multiple times even though
# the app has been offline the whole time.


# Map from CRUD to HTTP for our default `Backbone.sync` implementation.
methodMap =
  'create': 'POST',
  'update': 'PUT',
  'patch':  'PATCH',
  'delete': 'DELETE',
  'read':   'GET'

# Local storage.
window.a = burry = new Burry.Store('offline_changes')

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
    if success then success(model, resp, options)
    model.trigger('sync', model, resp, options)

  error = options.error
  options.error = (xhr) ->
    console.log xhr # TODO set app state to offline if status is 0
    if xhr.status is 0
      console.log "We're offline!!!"
      app.state.set('online', false)
      saveOfflineChanges(model, _.extend(params, options))
    if error then error(model, xhr, options)
    model.trigger('error', model, xhr, options)

  # if we're online, do normal sync.
  if app.state.get('online')
    if params.type in ['POST', 'PUT', 'PATCH']
      # Persist changes locally.
      @saveLocal()

    console.log _.extend(params, options)
    # Make the request, allowing the user to override any Ajax options.
    xhr = options.xhr = Backbone.ajax(_.extend(params, options))
    model.trigger('request', model, xhr, options)
    return xhr
  else
    saveOfflineChanges(model, _.extend(params, options))
    if success then success(model, { status: 200 }, options)
    model.trigger('sync', model, { status: 200 }, options)

saveOfflineChanges = (model, options) ->
  if options.type is "GET" then return
  unless model.constructor.name is 'Post' then return

  console.log model, options

  # Ensure there's a created date.
  unless model.get('created')?
    console.log 'setting created'
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

 window.replayChanges = ->
  operations = []
  for key in burry.keys()
    model = burry.get(key)
    model._operation = key.split('::')[1]
    model._key = key

    operations.push model

  console.log operations

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

    model = _.extend.apply this, modelGroup

    if modelGroup.length > 1
      model._operation = winningOperation

    return model

  console.log operations

  for model in operations
    operation = model._operation
    key = model._key
    model._operation = null
    model._key = null

    # TODO get jquery ajax promise and only remove key if sync is successful.
    if operation is 'POST'
      # Delete temp version of post from the Posts collection cache.
      app.collections.posts.burry.remove(key.split('::')[2])

      # Delete our temporary IDs so that model.save will still create the model
      # on the server.
      model.id = null
      model.nid = null
      console.log 'creating new post', model
      app.collections.posts.create model

    else if operation is "PUT"
      app.collections.posts.getByNid(model.nid).set(model).save()

    else if operation is "DELETE"
      # If the model is in the posts collection, delete it immediatly.
      if app.collections.posts.getByNid(model.nid)?
        app.collections.posts.getByNid(model.nid).destroy()
      # Else load it off the server and then destroy it.
      else
        model = app.util.loadPostModel(model.nid, true)
        model.once('sync', -> if model.destroy then model.destroy())

    # Remove every burry operation on this post.
    nid = key.split('::')[2]
    for id in burry.keys()
      if _.str.contains(id, nid)
        burry.remove(id)
