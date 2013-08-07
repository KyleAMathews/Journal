PostEditTemplate = require 'views/templates/edit_post'
{ExpandingTextareaView} = require('widgets/expanding_textarea/expanding_textarea_view')
class exports.PostEditView extends Backbone.View

  id: 'post-edit'

  initialize: ->
    @throttledAutoScroll = _.throttle(@_autoscroll, 250)
    app.models.editing = @model

  events:
    'click .save': 'save'
    'click .delete': 'delete'
    'click .cancel': 'cancel'
    'click .show-date-edit': 'toggleDateEdit'
    'click .save-draft': 'draftSave'
    'keypress': '_draftSave'
    'keydown .body textarea': 'throttledAutoScroll'

  render: ->
    # If still loading the model.
    if (@model.get('nid')? or @model.id?) and (@model.get('body') is "" or @model.get('title') is "")
      @$el.html "<h2>Loading post... #{ app.templates.throbber('show', '21px') } </h2>"
    else
      _.defer => @lineheight = @$('.textareaClone div').css('line-height').slice(0,-2)
      @keystrokecounter = 0
      @$el.html PostEditTemplate @model.toJSON()
      @$('.date-edit').kalendae()
      @addChildView new ExpandingTextareaView(
        el: @$('.title')
        edit_text: @model.get('title')
        placeholder: 'Type your title here&hellip;'
        lines: 1
      ).render()
      lines = Math.min(18, Math.round(($(window).height() - 300) / 21))
      @addChildView new ExpandingTextareaView(
        el: @$('.body')
        edit_text: @model.get('body')
        placeholder: 'Start typing your post here&hellip;'
        lines: lines
      ).render()

      _.defer =>
        if @options.focusTitle
          @$('.title textarea').focus()

      # Show the edit button for the date field when hovering.
      @$('.date').hover(
        => @$('.show-date-edit').show()
        ,
        => @$('.show-date-edit').hide()
      )

    @

  # Keep the save button visible by autoscrolling.
  _autoscroll: (e) =>
    # Autoscrolling works poorly on touch devices due to small screen plus not really
    # helpful as user isn't navigating by keyboard.
    if Modernizr.touch then return

    # Measure distance from top of textarea to the top of the page.
    distanceTextareaToTop = $('.body textarea').offset().top
    textareaHeight = @$('.body textarea').height()
    # Measure distance from bottom of textarea to bottom of page.
    distanceToBottomOfWindowFromTextarea = $(window).height() - textareaHeight - (distanceTextareaToTop - $(window).scrollTop())

    # Measure how many values it is from current cursor position to the end of the
    # textarea.
    cursorPosition = @$('.body textarea')[0].selectionStart # Num of characters in textarea to cursor position.
    cursorMax = @$('.body textarea')[0].value.length # Total number of characters entered.
    distanceToEnd = cursorMax - cursorPosition

    # Count how many characters there are. We don't want to scroll down until
    # the person has typed several lines at least.
    numCharactersTyped = @$('.body textarea').val().length

    # See if the user is editing the title. If so, don't scroll.
    if $(document.activeElement).parents('.title').length > 0
      notInTitle = false
    else
      notInTitle = true

    # Only scroll down if the bottom of the textarea is very near the bottom of the page
    # and the cursor is within one line distance of the bottom of the textarea.
    if -50 < distanceToBottomOfWindowFromTextarea < 50 and distanceToEnd < 80 and
      numCharactersTyped > 400 and notInTitle
        $("html, body").animate({ scrollTop: $(document).height()-$(window).height() })

    # Scroll up if within 80 pixels of the top and we're not already at the top.
    if cursorPosition < 5 and
    $(window).scrollTop() > (distanceTextareaToTop - 150) # Don't scroll up if already near the top.
      $("html, body").animate({ scrollTop: Math.max(0, distanceTextareaToTop - 150) })

  errorMessage: (message) ->
    @$('.error').html(message).show()

  save: ->
    obj = {}
    obj.title = _.str.trim @$('.title textarea').val()
    obj.body = _.str.trim @$('.body textarea').val()

    if obj.title is ""
      return @errorMessage('You are missing your title')
    if obj.body is ""
      return @errorMessage('You are missing the body of your post')

    # See if the date was changed.
    created = @$('.date-edit').val()
    newDate = moment(created).hours(12)
    oldDate = moment(@model.get('created'))
    diff = newDate.diff(oldDate)
    if Math.abs(diff) > 86400000 # one day in miliseconds
      obj.created = newDate.format()

    # Add latitude and longitude.
    unless @model.get('latitude')? or @model.get('longitude')?
      pos = app.geolocation.getLatitudeLongitude()
      obj.latitude = pos.latitude
      obj.longitude = pos.longitude

    # Not a draft anymore.
    @model.set('draft', false)

    # Save it.
    @$('.js-loading').css('display', 'inline-block')
    @model.save(obj,
      success: @modelSynced
      error: @modelSynced
    )

  # Once the model is done syncing,
  # force a re-render of postsView and go back.
  modelSynced: (model, response, options) =>
    console.log 'inside modelSynced'
    console.log model
    console.log @options
    @model.collection.add @model, silent: true
    app.collections.posts.trigger 'reset'

    # Update the Posts collection localstorage cache.
    app.collections.posts.setCacheIds()

    # Going back, except when creating a new post, means going back to the home page.
    unless @options.newPost
      window.history.back()
    else
      app.router.navigate '/node/' + @model.get('nid'), true


  delete: ->
    app.collections.posts.remove @model
    app.collections.posts.sort()
    app.collections.posts.trigger 'reset'
    app.router.navigate '/', true
    @model.destroy()

  cancel: ->
    window.history.back()

  toggleDateEdit: ->
    @$('.date').hide()
    @$('.date-edit').show()

  _draftSave: ->
    # Save if this is a new post or a draft.
    if @options.newPost or @model.get('draft')
      # Autosave two seconds after last time user types.
      clearTimeout(@saveDraftAfterDelay)
      @saveDraftAfterDelay = setTimeout(@draftSave, 2000)
      @keystrokecounter += 1
      if @keystrokecounter % 20 is 0
        @draftSave()

  draftSave: () =>
    @model.set('title', @$('.title textarea').val())
    @model.set('body', @$('.body textarea').val())
    @model.set('draft', true)
    @model.save(null,
      {
        # Indicate in UI that the draft was saved.
        success: (model) =>
          # Update (or show) the "last saved" message.
          @$('#last-saved').html "Last saved at " + new moment().format('h:mm:ss a')
      }
    )

  onClose: ->
    clearTimeout(@saveDraftAfterDelay)
    app.models.editing = null
