class exports.Post extends Backbone.Model

  initialize: ->
    @set rendered_body: marked(@get('body'))
    @set rendered_created: moment(@get('created')).format("dddd, MMMM Do YYYY")
