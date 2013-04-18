module.exports = class MenuBarView extends Backbone.View

  initialize: ->
    @throttledScroll = _.throttle(@scrollManagement, 25)
    if Modernizr.touch
      $(window).on 'scroll', @throttledScroll

  events:
    'click .home-link': 'travelHome'

  travelHome: ->
    app.eventBus.trigger 'menuBar:click-home'

  scrollManagement: =>
    @current = $(window).scrollTop()
    if @last?
      if @current < @last
        # We're scrolling up now so reset the menu bar just above the visible
        # window.
        if @scrollingDirection is "down"
          pos = @current - 50
          @$el.css('position', 'absolute')
          unless @isVisible()
            @$el.css('top', pos + "px")
        # If the menu bar is even with the top of the window, set to fixed.
        if @$el.offset().top >= @current
          @$el.css('position', 'fixed').css('top', 0)
        @scrollingDirection = "up"
      else
        # We're scrolling down now so set the menu bar to an absolute position
        # so it'll scroll off the page.
        if @scrollingDirection is "up" or _.isUndefined @scrollingDirection
          @$el.css('position', 'absolute')
          unless @isVisible()
            @$el.css('top', @current + "px")
        @scrollingDirection = "down"
    @last = @current

  isVisible: ->
    return @$el.offset().top - @current > -50
