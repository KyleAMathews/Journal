_ = require 'underscore'
Backbone = require 'backbone'
raf = require 'raf'
log = require('bows')("EventBus")

window.eb = module.exports = _.extend {}, Backbone.Events

eb.on 'all', (name, params) ->
  log name, params

scrollTop = 0
handleScroll = ->
  newScrollTop = window.pageYOffset
  if scrollTop isnt newScrollTop
    scrollTop = newScrollTop
    eb.trigger 'scrollTop', scrollTop
    eb.trigger 'scrollBottom', document.body.scrollHeight - scrollTop - window.innerHeight

  raf(handleScroll)

raf handleScroll
