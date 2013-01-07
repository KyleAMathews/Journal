{PostsView} = require 'views/posts_view'
{PostView} = require 'views/post_view'
{PostEditView} = require 'views/post_edit_view'
{Post} = require 'models/post'
Draft = require 'models/draft'
SearchView = require 'views/search_view'

class exports.MainRouter extends Backbone.Router

  initialize: ->
    # Define global keyboard shortcuts.
    key('s,/', -> app.router.navigate('search', true))
    key('h', -> app.router.navigate('', true))

  routes:
    '': 'home'
    'node/:id': 'post'
    'posts/new': 'newPost'
    'node/:id/edit': 'editPost'
    'draft/:id': 'editDraft'
    'search': 'search'
    'search/:query': 'search'

  home: ->
    $('#container').hide()
    $('#posts').show()
    app.eventBus.trigger 'posts:show'

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

  search: (query = "") ->
    unless query is ""
      app.collections.search.query(query)
    else
      app.collections.search.clear()
    searchView = new SearchView collection: app.collections.search
    app.views.main.show(searchView)
