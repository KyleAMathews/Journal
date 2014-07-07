Emitter = require('wildemitter')
log = require('bows')("dispatcher")

Dispatcher = new Emitter()

Dispatcher.on '*', (action, args...) ->
  log action, args

module.exports = Dispatcher
