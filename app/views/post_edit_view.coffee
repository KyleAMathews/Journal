PostEditTemplate = require 'views/templates/edit_post'
{ExpandingTextareaView} = require('widgets/expanding_textarea/expanding_textarea_view')
class exports.PostEditView extends Backbone.View

  id: 'post-edit'

  events:
    'click .save': 'save'
    'click .delete': 'delete'
    'click .show-date-edit': 'toggleDateEdit'

  render: ->
    @$el.html PostEditTemplate @model.toJSON()
    @$('.date-edit').kalendae()
    @addChildView new ExpandingTextareaView(
      el: @$('.expanding-textarea')
      edit_text: @model.get('body')
      lines: 20
    ).render()

    @$('.date').hover(
      => @$('.show-date-edit').show()
      ,
      => @$('.show-date-edit').hide()
    )

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
          app.collections.posts.sort()
          app.router.navigate '/node/' + @model.get('nid'), true
      }
    )

  delete: ->
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
