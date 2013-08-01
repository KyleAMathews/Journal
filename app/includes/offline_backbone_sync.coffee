# TODO
#
# Remove drafts
#
# create the new post with current draft logic with draft flas set to true.
# run an update script which converts all drafts into posts w/ flag set to true
# Change drafts api call to get all models with draft set to true and regular
# POSTS get should ignore draft models.
#
# replay the offline changes in order of changes, e.g. read into array and order
# by change date.
#
# save new post models created offline into the localstorage so they're loaded
# when reloading the app so can load and edit multiple times even though
# the app has been offline the whole time.
#
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
    if error then error(model, xhr, options)
    model.trigger('error', model, xhr, options)

  # if we're online, do normal sync.
  if app.state.get('online')
    if params.type in ['POST', 'PUT', 'PATCH']
      # Persist changes locally.
      @saveLocal()

    saveOfflineChanges(model, _.extend(params, options))

    console.log _.extend(params, options)
    # Make the request, allowing the user to override any Ajax options.
    xhr = options.xhr = Backbone.ajax(_.extend(params, options))
    model.trigger('request', model, xhr, options)
    return xhr
  else
    saveOfflineChanges(model, _.extend(params, options))

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
  unless model.id then model.id = "OFFLINE_#{ Math.round(Math.random() * 100000) }"
  unless model.get('nid') then model.set('nid', Math.round(Math.random() * 100000) + 1000000)

  key = "#{ options.type }::#{model.get('nid')}"
  burry.set(key, model.toJSON())

app.state.on 'change:online', (model, online) ->
  if online and burry.keys().length > 0
    replayChanges()

 window.replayChanges = ->
   for key in burry.keys()
     method = key.split('::')[0]
     model = app.collections.posts.burry.get(key.split('::')[1])

     if method is 'POST'
       # Delete our temporary ID so that model.save will still create the model
       # on the server.
       if model?
         model.id = null
         model.unset('id')
         model.unset('nid')
       # The model isn't in the POSTS collection anymore as 
       else
         app.collections.posts.create burry.get(key)

     unless model?
       return burry.remove(key)

     model.save()

     burry.remove(key)
