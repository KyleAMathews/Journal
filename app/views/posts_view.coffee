{PostView} = require 'views/post_view'
PostsTemplate = require 'views/templates/posts'

class exports.PostsView extends Backbone.View

  id: 'posts'

  initialize: ->
    @bindTo @collection, 'reset', @render
    @bindTo @collection, 'add', @addOne
    @bindTo @collection, 'loading-posts', -> @$('#loading-posts').show()
    @bindTo @collection, 'done-loading-posts', -> @$('#loading-posts').hide()

  render: =>
    @$el.html PostsTemplate()
    @addAll()

    # Scroll to last place on screen.
    _.defer ->
      scrollPosition = app.site.get 'postsScroll'
      $(window).scrollTop(scrollPosition)

    @

  addAll: ->
    for post in @collection.models
      @addOne post

  addOne: (post) =>
    postView = new PostView model: post
    @$('#posts').append postView.render().el
