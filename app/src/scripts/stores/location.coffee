Reflux = require 'reflux'

location = {}

module.exports = LocationStore = Reflux.createStore

  init: ->
    if navigator.geolocation
      console.log('Geolocation is supported!')
      navigator.geolocation.getCurrentPosition @success, @error
    else
      console.log(
        'Geolocation is not supported for this Browser/OS version yet.'
      )

  success: (position) ->
    console.log position
    location = {
      latitude: position.coords?.latitude
      longitude: position.coords?.longitude
    }

    @trigger location

  error: (error) ->
    console.log "geolocation error", error

  getInitialState: ->
    location
