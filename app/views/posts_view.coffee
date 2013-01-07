{PostView} = require 'views/post_view'
PostsTemplate = require 'views/templates/posts'

class exports.PostsView extends Backbone.View

  id: 'posts'

  initialize: ->
    @listenTo @collection, 'reset', @render
    @listenTo @collection, 'add', @addOne
    @listenTo @collection, 'loading-posts', -> @showLoading()
    @listenTo @collection, 'done-loading-posts', -> @hideLoading()
    app.eventBus.trigger 'postsView:active', true


  render: =>
    @$el.html PostsTemplate()
    if @collection.isLoading then @showLoading() else @hideLoading()

    # Create infinity.js listView
    if @listView then @listView.remove()
    @listView = new infinity.ListView(@$('.posts-listview'))

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
    postView.render()
    _.defer =>
      @listView.append postView.$el

  onClose: ->
    @listView.remove()
    app.eventBus.trigger 'postsView:active', false
