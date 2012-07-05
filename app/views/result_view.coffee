ResultTemplate = require 'views/templates/result'
module.exports = class ResultView extends Backbone.View

  className: 'search-result'

  render: ->
    if @model.get('highlight').title?[0]?
      title = @model.get('highlight').title?[0]
    else
      title = @model.get('_source').title
    if @model.get('highlight').body?[0]?
      body = @model.get('highlight').body?[0]
    else
      body = _.prune(@model.get('_source').body, 200)
    @$el.html ResultTemplate {
      title: title
      body: body
      created: moment(@model.get('_source').created).format("D MMMM YYYY")
      link: '/node/' + @model.get('_source').nid
    }
    @
