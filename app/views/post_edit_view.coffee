PostEditTemplate = require 'views/templates/edit_post'
{ExpandingTextareaView} = require('widgets/expanding_textarea/expanding_textarea_view')
class exports.PostEditView extends Backbone.View

  id: 'post-edit'

  events:
    'click .save': 'save'
    'click .delete': 'delete'
    'click .cancel': 'cancel'
    'click .show-date-edit': 'toggleDateEdit'
    'click .save-draft': 'draftSave'
    'keypress': '_draftSave'

  render: ->
    # If still loading the model.
    if (@model.get('nid')? or @model.id?) and (@model.get('body') is "" or @model.get('title') is "")
      @$el.html "<h2>Loading post&hellip; <img width='32px' height='32px' src='/images/loading.gif' /></h2>"
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
      @addChildView new ExpandingTextareaView(
        el: @$('.body')
        edit_text: @model.get('body')
        placeholder: 'Start typing your post here&hellip;'
        lines: 20
      ).render()

      # Show the edit button for the date field when hovering.
      @$('.date').hover(
        => @$('.show-date-edit').show()
        ,
        => @$('.show-date-edit').hide()
      )

      # Keep the save button visible by autoscrolling.
      autoscroll = (e) =>
        # Measure distance from bottom of textarea to bottom of page.
        distanceTextareaToTop = $('.body textarea').offset().top - $(document).scrollTop()
        textareaHeight = @$('.body textarea').height()
        distanceToBottomFromTextarea = $(window).height() - textareaHeight - distanceTextareaToTop

        # Measure how many values it is from current cursor position to the end of the
        # textarea.
        cursorPosition = @$('.body textarea')[0].selectionStart
        cursorMax = @$('.body textarea')[0].value.length
        distanceToEnd = cursorMax - cursorPosition

        # See if the user is editing the title. If so, don't scroll.
        if $(document.activeElement).parents('.title').length > 0
          notInTitle = false
        else
          notInTitle = true

        # Only scroll if the bottom of the textarea is very near the bottom of the page
        # and the cursor is within one line distance of the bottom of the textarea.
        if -50 < distanceToBottomFromTextarea < 50 and distanceToEnd < 80 and notInTitle
          $("html, body").animate({ scrollTop: $(document).height()-$(window).height() })
      throttled = _.throttle(autoscroll, 200)
      @$('textarea').on('keypress', throttled)

    @

  save: ->
    obj = {}
    obj.title = @$('.title textarea').val()
    obj.body = @$('.body textarea').val()

    # See if the date was changed.
    created = @$('.date-edit').val()
    newDate = moment(created).hours(12)
    oldDate = moment(@model.get('created'))
    diff = newDate.diff(oldDate)
    if Math.abs(diff) > 86400000 # one day in miliseconds
      obj.created = newDate.format()

    # Save it.
    @$('.loading').show()
    @model.save(obj, success: @modelSynced)

  # Once the model is done syncing, cleanup the draft model
  # force a re-render of postsView and go back.
  modelSynced: (model, response, options) =>
    if @options.draftModel?
      @options.draftModel.destroy()
      newPost = true
    @model.collection.add @model, silent: true
    app.collections.posts.trigger 'reset'
    unless newPost
      window.history.back()
    # Back, in the case of a new post, means back to the home page which isn't the
    # expected behavior when creating a new post.
    else
      app.router.navigate '/node/' + @model.get('nid'), true


  delete: ->
    if @options.draftModel? then @options.draftModel.destroy()
    @model.save({ deleted: true },
      {
        success: =>
          app.collections.posts.remove @model
          app.collections.posts.sort()
          app.collections.posts.trigger 'set_cache_ids'
          app.collections.posts.trigger 'reset'
          app.router.navigate '/', true
      }
    )

  cancel: ->
    window.history.back()

  toggleDateEdit: ->
    @$('.date').hide()
    @$('.date-edit').show()

  _draftSave: ->
    if @options.draftModel?
      # Autosave two seconds after last time user types.
      clearTimeout(@saveDraftAfterDelay)
      @saveDraftAfterDelay = setTimeout(@draftSave, 2000)
      @keystrokecounter += 1
      if @keystrokecounter % 20 is 0
        @draftSave()

  draftSave: (e) =>
    if @options.draftModel?
      obj = {}
      obj.title = @$('.title textarea').val()
      obj.body = @$('.body textarea').val()
      @options.draftModel.save(obj,
        {
          # Indicate in UI that the draft was saved.
          success: (model) =>
            # Merge changes into drafts collection.
            app.collections.drafts.add(model, merge: true)
            @$('#last-saved').html "Last saved at " + new moment().format('h:mm:ss a')
        }
      )

  onClose: ->
    clearTimeout(@saveDraftAfterDelay)
