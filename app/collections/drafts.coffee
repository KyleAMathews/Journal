Draft = require 'models/draft'

module.exports = class Drafts extends Backbone.Collection

  url: '/drafts'
  model: Draft

  initialize: ->
    @burry = new Burry.Store('drafts', 30240)

  comparator: (model, model2) ->
    if model.get('created') is model2.get('created') then return 0
    if model.get('created') < model2.get('created') then return 1 else return -1
