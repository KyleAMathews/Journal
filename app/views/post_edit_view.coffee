PostEditTemplate = require 'views/templates/edit_post'
{ExpandingTextareaView} = require('widgets/expanding_textarea/expanding_textarea_view')
class exports.PostEditView extends Backbone.View

  id: 'post-edit'

  events:
    'click .save': 'save'

  render: ->
    @$el.html PostEditTemplate @model.toJSON()
    @$('.date').kalendae()
    @addChildView new ExpandingTextareaView(
      el: @$('.expanding-textarea')
      edit_text: @model.get('body')
      lines: 20
    ).render()

    @

  save: ->
    obj = {}
    obj.title = @$('.title').val()
    obj.body = @$('textarea').val()

    # See if the date was changed.
    created = @$('.date').val()
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
