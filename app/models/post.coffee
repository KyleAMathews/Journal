class exports.Post extends Backbone.Model

  sync: Backbone.cachingSync(Backbone.sync, 'posts', null, true)

  defaults:
    title: ''
    body: ''
    created: new Date().toISOString()

  initialize: ->
    @on 'request', ->
      @set rendered_body: marked(@get('body'))
      @set rendered_created: moment(@get('created')).format("dddd, MMMM Do YYYY")
