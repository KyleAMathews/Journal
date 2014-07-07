Dispatcher = require '../dispatcher'
AppConstants = require '../constants/app_constants'
Emitter = require('wildemitter')

CHANGE_EVENT = "change"

_appState = {}

class AppStore extends Emitter
  getAll: ->
    return _appState

  get: (key) ->
    return _appState[key]

  set: (key, value) ->
    _appState[key] = value

  emitChange: ->
    @emit CHANGE_EVENT

module.exports = window.appstore = AppStore = new AppStore()

# Register to dispatcher.
Dispatcher.on '*', (action, args...) ->
  switch action
    when AppConstants.POSTS_INDEX_SCROLL_POSITION_UPDATE
      AppStore.set 'posts_index_scroll_position', args[0]

