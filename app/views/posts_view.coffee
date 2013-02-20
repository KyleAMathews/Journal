{PostView} = require 'views/post_view'
PostsTemplate = require 'views/templates/posts'

class exports.PostsView extends Backbone.View

  id: 'posts'

  initialize: ->
    @debouncedCachePostPositions = _.debounce (=> @cachePostPositions()), 100
    @listenTo @collection, 'reset add remove', @debouncedCachePostPositions
    @listenTo @collection, 'reset', @render
    @listenTo @collection, 'add', @addOne
    @listenTo @collection, 'loading-posts', @showLoading
    @listenTo @collection, 'done-loading-posts', @hideLoading
    # When an individual post or a postEdit view is loaded, hide.
    @listenTo app.eventBus, 'pane:show', -> @$el.hide()
    # We're live, scroll to the last position.
    @listenTo app.eventBus, 'posts:show', -> @scrollLastPostion()
    app.eventBus.on 'distance:bottom_page', ((distance) =>
      # Don't load more posts while the postsView is hidden.
      if @$el.is(':hidden') then return
      if distance <= 1500 then @collection.load()
    ), @
    key('j', => @scrollNext())
    key('k', => @scrollPrevious())


  render: =>
    @$el.html PostsTemplate()
    if @collection.isLoading then @showLoading() else @hideLoading()

    @addAll()

    # Time to initial render.
    _.defer =>
      console.log (new Date().getTime() - performance.timing.navigationStart) / 1000
      @debouncedCachePostPositions()

    @

  scrollLastPostion: ->
    # Scroll to last place on screen.
    scrollPosition = app.site.get 'postsScroll'
    $(window).scrollTop(scrollPosition)

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
    @$('.posts').append postView.el

  onClose: ->
    app.eventBus.trigger 'postsView:active', false

  cachePostPositions: ->
    @postPositions = []
    for post in @$('.post')
      @postPositions.push $(post).offset().top

  scrollNext: ->
    curPosition = $(window).scrollTop() + 81
    nextY = _.find @postPositions, (y) -> curPosition < y
    window.scrollTo(0, nextY - 80) # 42 px for the header + 36 px for two lines.

  scrollPrevious: ->
    curPosition = $(window).scrollTop() + 79
    copyPostPostions = @postPositions.slice(0).reverse()
    nextY = _.find copyPostPostions, (y) -> curPosition > y
    window.scrollTo(0, nextY - 80) # 42 px for the header + 36 px for two lines.
