class exports.Post extends Backbone.Model

  defaults:
    title: ''
    body: ''
    created: new Date().toISOString()
