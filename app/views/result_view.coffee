ResultTemplate = require 'views/templates/result'
module.exports = class ResultView extends Backbone.View

  className: 'search-result'

  render: ->
    if @model.get('highlight').title?[0]?
      title = @model.get('highlight').title?[0]
    else
      title = @model.get('source').title
    if @model.get('highlight').body?[0]?
      body = @model.get('highlight').body?[0]
    else
      body = _.prune(@model.get('source').body, 200)
    @$el.html ResultTemplate {
      title: title
      body: body
      link: '/node/' + @model.get('source').nid
    }
    @
