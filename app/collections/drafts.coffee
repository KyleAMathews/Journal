Draft = require 'models/draft'

module.exports = class Drafts extends Backbone.Collection

  url: '/drafts'
  model: Draft
