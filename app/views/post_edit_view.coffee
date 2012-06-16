PostEditTemplate = require 'views/templates/edit_post'
{ExpandingTextareaView} = require('widgets/expanding_textarea/expanding_textarea_view')
class exports.PostEditView extends Backbone.View

  id: 'post-edit'

  events:
    'click .save': 'save'
    'click .delete': 'delete'
    'click .show-date-edit': 'toggleDateEdit'
    'click .save-draft': 'draftSave'
    'keypress': '_draftSave'

  render: ->
    _.defer => @lineheight = @$('.textareaClone div').css('line-height').slice(0,-2)
    @keystrokecounter = 0
    @$el.html PostEditTemplate @model.toJSON()
    @$('.date-edit').kalendae()
    @addChildView new ExpandingTextareaView(
      el: @$('.expanding-textarea')
      edit_text: @model.get('body')
      lines: 20
    ).render()

    # Show the edit button for the date field when hovering.
    @$('.date').hover(
      => @$('.show-date-edit').show()
      ,
      => @$('.show-date-edit').hide()
    )

    # Keep the save button visible by autoscrolling.
    #autoscroll = (e) =>
      #lines = @$('.textareaClone div').height() / @lineheight
      #if lines < 18 then return # Only scroll when typing near bottom of textarea.
      #distanceBottom = $(document).height() - ($(window).scrollTop() + $(window).height())
      #if distanceBottom > 20
        #$("html, body").animate({ scrollTop: $(document).height()-$(window).height() })
    #throttled = _.throttle(autoscroll, 200)
    #@$('textarea').on('keypress', throttled)

    @

  save: ->
    obj = {}
    obj.title = @$('.title').val()
    obj.body = @$('textarea').val()

    # See if the date was changed.
    created = @$('.date-edit').val()
    newDate = moment(created).hours(12)
    oldDate = moment(@model.get('created'))
    diff = newDate.diff(oldDate)
    if Math.abs(diff) > 86400000 # one day in miliseconds
      obj.created = newDate.format()

    # Save it.
    @$('.loading').show()
    @model.save(obj,
      {
        success: =>
          if @options.draftModel? then @options.draftModel.destroy()
          app.collections.posts.sort()
          app.router.navigate '/node/' + @model.get('nid'), true
      }
    )

  delete: ->
    if @options.draftModel? then @options.draftModel.destroy()
    @model.save({ deleted: true },
      {
        success: =>
          app.collections.posts.remove @model
          app.collections.posts.sort()
          app.router.navigate '/', true
      }
    )

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
      obj.title = @$('.title').val()
      obj.body = @$('textarea').val()
      @options.draftModel.save(obj,
        {
          success: =>
            # Add new draft to its collection.
            unless app.collections.drafts.get @options.draftModel.id
              app.collections.drafts.add @options.draftModel
            @$('#last-saved').html "Last saved at " + new moment().format('h:mm:ss a')
        }
      )

  onClose: ->
    clearTimeout(@saveDraftAfterDelay)
