Draft = require 'models/draft'

module.exports = class Drafts extends Backbone.Collection

  url: '/drafts'
  model: Draft

  initialize: ->
    # Convert old stand alone drafts into new post drafts.
    @on 'sync', =>
      for draft in @models
        app.collections.posts.create({
          title: draft.get('title')
          body: draft.get('body')
          created: draft.get('created')
          changed: draft.get('changed')
          draft: true
        })
        draft.destroy()


  comparator: (model, model2) ->
    if model.get('created') is model2.get('created') then return 0
    if model.get('created') < model2.get('created') then return 1 else return -1
