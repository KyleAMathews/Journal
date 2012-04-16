{PostView} = require 'views/post_view'
class exports.PostsView extends Backbone.View

  initialize: ->
    @collection.on 'reset', @render

  render: =>
    @addAll()
    @

  addAll: ->
    for post in @collection.models
      @addOne post

  addOne: (post) ->
    postView = new PostView model: post
    @$el.append postView.render().el
