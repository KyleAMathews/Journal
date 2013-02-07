class Geolocation
  constructor: ->
    # check for Geolocation support
    if navigator.geolocation
      console.log('Geolocation is supported!')
      navigator.geolocation.getCurrentPosition @success, @error
    else
      console.log('Geolocation is not supported for this Browser/OS version yet.')


  success: (position) =>
    @position = position

  error: (error) =>
    console.log error
    @error = error

  getLatitudeLongitude: ->
    return latitude: @position.coords.latitude, longitude: @position.coords.longitude

 module.exports = new Geolocation()
