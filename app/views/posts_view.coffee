{PostView} = require 'views/post_view'
PostsTemplate = require 'views/templates/posts'

class exports.PostsView extends Backbone.View

  id: 'posts'

  initialize: ->
    @listenTo @collection, 'reset', @render
    @listenTo @collection, 'add', @addOne
    @listenTo @collection, 'loading-posts', @showLoading
    @listenTo @collection, 'done-loading-posts', @hideLoading

    # When an individual post or a postEdit view is loaded, hide.
    @listenTo app.eventBus, 'pane:show', -> @$el.hide()

    # We're live, scroll to the last position.
    @listenTo app.eventBus, 'posts:show', -> @scrollLastPostion()

    @listenTo app.eventBus, 'keydown', (keycode) =>
      if keycode is 74 # j
        @scrollNext()
      if keycode is 75 # k
        @scrollPrevious()

    # If the home link is clicked while on the PostsView, scroll to the top.
    @listenTo app.eventBus, 'menuBar:click-home', =>
      if @isVisible()
        $("html, body").animate({ scrollTop: 0 })

    @listenTo app.eventBus, 'distance:bottom_page', ((distance) =>
      # Don't load more posts while the postsView is hidden.
      if @$el.is(':hidden') then return
      if distance <= 1500 then @collection.load()
    ), @


  render: =>
    @$el.html PostsTemplate()
    if @collection.isLoading then @showLoading() else @hideLoading()

    @addAll()

    # Time to initial render.
    _.defer =>
      console.log "rendering postsView", (new Date().getTime() - performance.timing.navigationStart) / 1000

    @

  scrollLastPostion: ->
    # Scroll to last place on screen.
    scrollPosition = app.site.get 'postsScroll'
    $(window).scrollTop(scrollPosition)

  showLoading: ->
    @$('#loading-posts').show()
    @$('.js-top-loading').show()

  hideLoading: ->
    @$('#loading-posts').hide()
    @$('.js-top-loading').hide()

  addAll: ->
    for post in @collection.models
      @addOne post

  # TODO make this function smarter about order i.e. it knows index of post
  # so render post in that place within its views.
  addOne: (post) =>
    postView = new PostView model: post
    postView.render()
    @$('.posts').append postView.el

  onClose: ->
    app.eventBus.trigger 'postsView:active', false

  # Scroll to the next post.
  scrollNext: ->
    nextY = @collection.posNext()
    unless _.isUndefined nextY
      window.scrollTo(0, nextY - 80) # 42 px for the header + 36 px for two lines.

  # Scroll to the previous post.
  scrollPrevious: ->
    prevY = @collection.posPrev()
    unless _.isUndefined prevY
      window.scrollTo(0, prevY - 80) # 42 px for the header + 36 px for two lines.

  isVisible: ->
    return @$el.is(':visible')
