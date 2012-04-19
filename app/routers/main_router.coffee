{PostView} = require 'views/post_view'
{PostEditView} = require 'views/post_edit_view'
{Post} = require 'models/post'
class exports.MainRouter extends Backbone.Router
  routes:
    '': 'home'
    'node/:id': 'post'
    'posts/new': 'newPost'
    'node/:id/edit': 'editPost'

  home: ->
    app.views.main.show(app.views.posts)

  post: (id) ->
    app.util.loadPost id, true, (post) ->
      # Scroll to top of page.
      document.body.scrollTop = document.documentElement.scrollTop = 0
      postView = new PostView model: post, page: true
      app.views.main.show(postView)

  newPost: ->
    # Scroll to top of page.
    document.body.scrollTop = document.documentElement.scrollTop = 0
    newPost = new Post
    newPost.collection = app.collections.posts
    postEditView = new PostEditView model: newPost
    app.views.main.show(postEditView)

  editPost: (id) ->
    app.util.loadPost id, true, (post) ->
      # Scroll to top of page.
      document.body.scrollTop = document.documentElement.scrollTop = 0
      postEditView = new PostEditView model: post
      app.views.main.show(postEditView)
