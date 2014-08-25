_ = require 'underscore'
Backbone = require 'backbone'
raf = require 'raf'
log = require('bows')("EventBus")

window.eb = module.exports = _.extend {}, Backbone.Events

eb.on 'all', (name, params) ->
  unless name in ["scrollTop", "scrollBottom"]
    log name, params

# Send out on event bus the distance to the top and bottom of the page.
scrollTop = 0
handleScroll = ->
  newScrollTop = window.pageYOffset
  if scrollTop isnt newScrollTop
    scrollTop = newScrollTop
    eb.trigger 'scrollTop', scrollTop
    eb.trigger 'scrollBottom', document.body.scrollHeight - scrollTop - window.innerHeight
  raf(handleScroll)
raf handleScroll
