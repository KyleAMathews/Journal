{PostView} = require 'views/post_view'
PostsTemplate = require 'views/templates/posts'

class exports.PostsView extends Backbone.View

  id: 'posts'

  initialize: ->
    @collection.on 'reset', @render
    @collection.on 'add', @addOne

  events:
    'click #load-more': 'loadMore'

  render: =>
    @$el.html PostsTemplate()
    @addAll()
    @

  addAll: ->
    for post in @collection.models
      @addOne post

  addOne: (post) =>
    postView = new PostView model: post
    @$('#posts').append postView.render().el

  loadMore: ->
    @collection.fetch
      add: true
      data:
        skip: @collection.length
