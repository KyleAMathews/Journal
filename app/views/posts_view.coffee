{PostView} = require 'views/post_view'
PostsTemplate = require 'views/templates/posts'

class exports.PostsView extends Backbone.View

  id: 'posts'

  initialize: ->
    @bindTo @collection, 'reset', @render
    @bindTo @collection, 'add', @addOne
    @bindTo @collection, 'loading-posts', -> @showLoading()
    @bindTo @collection, 'done-loading-posts', -> @hideLoading()


  render: =>
    @$el.html PostsTemplate()
    if @collection.isLoading then @showLoading() else @hideLoading()

    # Create infinity.js listView
    @listView = new infinity.ListView(@$('.posts'))

    @addAll()

    # Scroll to last place on screen.
    _.defer ->
      scrollPosition = app.site.get 'postsScroll'
      $(window).scrollTop(scrollPosition)

    @

  showLoading: ->
    @$('#loading-posts').show()

  hideLoading: ->
    @$('#loading-posts').hide()

  addAll: ->
    for post in @collection.models
      @addOne post

  addOne: (post) =>
    postView = new PostView model: post
    @listView.append postView.render().$el
