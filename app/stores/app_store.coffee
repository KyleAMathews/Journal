Dispatcher = require '../dispatcher'
AppConstants = require '../constants/app_constants'
Emitter = require('wildemitter')

CHANGE_EVENT = "change"

_appState = {}

set = (key, value) ->
  _appState[key] = value

# Get latitude and longitude
success = (position) ->
  set 'coordinates', position.coords

error = (error) ->
  console.log error

# check for Geolocation support
if navigator.geolocation
  console.log('Geolocation is supported!')
  navigator.geolocation.getCurrentPosition success, error
else
  console.log('Geolocation is not supported for this Browser/OS version yet.')

class AppStore extends Emitter
  getAll: ->
    return _appState

  get: (key) ->
    return _appState[key]

  emitChange: ->
    @emit CHANGE_EVENT

module.exports = window.appstore = AppStore = new AppStore()

# Register to dispatcher.
Dispatcher.on '*', (action, args...) ->
  switch action
    when AppConstants.POSTS_INDEX_SCROLL_POSITION_UPDATE
      set 'posts_index_scroll_position', args[0]
    when AppConstants.SEARCH_CACHE
      set args[0], args[1]
