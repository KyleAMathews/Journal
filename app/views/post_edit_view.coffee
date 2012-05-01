PostEditTemplate = require 'views/templates/edit_post'
class exports.PostEditView extends Backbone.View

  className: 'post-edit'

  events:
    'click .save': 'save'

  render: ->
    @$el.html PostEditTemplate @model.toJSON()
    @$('.date').kalendae()
    @

  save: ->
    obj = {}
    obj.title = @$('.title').val()
    obj.body = @$('.body').val()

    # See if the date was changed.
    created = @$('.date').val()
    newDate = moment(created).hours(12)
    oldDate = moment(@model.get('created'))
    diff = newDate.diff(oldDate)
    if Math.abs(diff) > 86400000 # one day in miliseconds
      obj.created = newDate.format()

    # Save it.
    @model.save(obj,
      {
        success: =>
          app.collections.posts.sort()
          app.router.navigate '/node/' + @model.get('nid'), true
      }
    )
