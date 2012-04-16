class exports.MainRouter extends Backbone.Router
  routes:
    '': 'home'

  home: ->
    $('ul#posts').html app.views.posts.render().el
