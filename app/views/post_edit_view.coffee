PostEditTemplate = require 'views/templates/edit_post'
class exports.PostEditView extends Backbone.View

  className: 'post-edit'

  events:
    'click .save': 'save'

  render: ->
    @$el.html PostEditTemplate @model.toJSON()
    @

  save: ->
    title = @$('.title').val()
    body = @$('.body').val()
    @model.save({
        title: title
        body: body
      },
      {
        success: =>
          app.router.navigate '/node/' + @model.get('nid'), true
      }
    )
