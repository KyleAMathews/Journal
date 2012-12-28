class exports.Post extends Backbone.Model

  sync: Backbone.cachingSync(Backbone.sync, 'posts', null, true)

  defaults:
    title: ''
    body: ''
    created: new Date().toISOString()
