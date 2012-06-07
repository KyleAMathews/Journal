{PostsView} = require 'views/posts_view'
{PostView} = require 'views/post_view'
{PostEditView} = require 'views/post_edit_view'
{Post} = require 'models/post'
Draft = require 'models/draft'

class exports.MainRouter extends Backbone.Router
  routes:
    '': 'home'
    'node/:id': 'post'
    'posts/new': 'newPost'
    'node/:id/edit': 'editPost'
    'draft/:id': 'editDraft'

  home: ->
    postsView = new PostsView collection: app.collections.posts
    app.views.main.show(postsView)

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
    draftModel = new Draft
    draftModel.collection = app.collections.drafts
    postEditView = new PostEditView model: newPost, draftModel: draftModel
    app.views.main.show(postEditView)

  editPost: (id) ->
    app.util.loadPost id, true, (post) ->
      # Scroll to top of page.
      document.body.scrollTop = document.documentElement.scrollTop = 0
      postEditView = new PostEditView model: post
      app.views.main.show(postEditView)

  editDraft: (id) ->
    draftModel = app.collections.drafts.get(id)
    newPost = new Post
    newPost.collection = app.collections.posts
    newPost.set title: draftModel.get('title'), body: draftModel.get('body')
    postEditView = new PostEditView model: newPost, draftModel: draftModel
    app.views.main.show(postEditView)
