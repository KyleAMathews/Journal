module.exports = class Starred extends Backbone.Collection

  initialize: ->
    @fetch()
    app.collections.posts.on 'change:starred', @maintainStarred
    app.collections.postsCache.on 'change:starred', @maintainStarred

  # When the user changes the starredness of a post, update this collection
  # as well.
  maintainStarred: (model, starred) =>
    if starred
      @add model, merge: true
    else
      @remove model

  fetch: ->
    $.getJSON('/posts?starred=true', (posts) =>
      @reset posts
      @trigger 'sync'
    )

  comparator: (model, model2) ->
    if model.get('created') is model2.get('created') then return 0
    if model.get('created') < model2.get('created') then return 1 else return -1
