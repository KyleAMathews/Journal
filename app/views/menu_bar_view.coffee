MenuDropdownView = require 'views/menu_dropdown_view'

module.exports = class MenuBarView extends Backbone.View

  initialize: ->
    @throttledScroll = _.throttle(@scrollManagement, 25)
    if Modernizr.touch
      $(window).on 'scroll', @throttledScroll

    @listenTo app.state, 'change:online', @toggleOnlineStatus

  events:
    'click .home-link': 'travelHome'
    'click .dropdown-menu': 'toggleDropdown'

  travelHome: ->
    app.eventBus.trigger 'menuBar:click-home'

  scrollManagement: =>
    @current = $(window).scrollTop()
    if @last?
      if @current < @last
        # We're scrolling up now so reset the menu bar just above the visible
        # window.
        if @scrollingDirection is "down"
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

  toggleDropdown: ->
    @$('.dropdown-menu').toggleClass('active')
    left = $('.dropdown-menu').offset().left
    if @dropdownView?
      @dropdownView.close()
      @dropdownView = null
    else
      @$('.dropdown-menu').append('<ul class="dropdown"></ul>')
      @dropdownView = new MenuDropdownView( el: @$('ul.dropdown') ).render()
      @dropdownView.parent = @

      menuBarPadding = 14
      widthDropdown = 252
      widthIcon = 21
      left = left - widthDropdown + widthIcon + menuBarPadding
      @$('ul.dropdown').css('left', left)
