module.exports = class MenuBarView extends Backbone.View

  events:
    'click .home-link': 'travelHome'

  travelHome: ->
    $("html, body").animate({ scrollTop: 0 })
