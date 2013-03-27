{PostsView} = require 'views/posts_view'
{PostView} = require 'views/post_view'
{PostEditView} = require 'views/post_edit_view'
Post = require 'models/post'
Draft = require 'models/draft'
SearchView = require 'views/search_view'

class exports.MainRouter extends Backbone.Router

  initialize: ->
    # Define routing keyboard shortcuts.
    key 's,/', => @search()
    key 'h', => @home()
    key 'n', => @newPost(true)

  routes:
    '': 'home'
    'node/:id': 'post'
    'posts/new': 'newPost'
    'node/:id/edit': 'editPost'
    'drafts/:id': 'editDraft'
    'search': 'search'
    'search/:query': 'search'

  home: ->
    $('#container').hide()
    $('#posts').show()
    app.eventBus.trigger 'posts:show'

  post: (id) ->
    post = app.util.loadPostModel id, true
    # Scroll to top of page.
    document.body.scrollTop = document.documentElement.scrollTop = 0
    postView = new PostView model: post, page: true
    app.views.main.show(postView)

  newPost: (focusTitle = false) ->
    # Scroll to top of page.
    document.body.scrollTop = document.documentElement.scrollTop = 0
    newPost = new Post {}, collection: app.collections.posts
    newPost.set created: new Date().toISOString()
    draftModel = new Draft {}, collection: app.collections.drafts
    postEditView = new PostEditView model: newPost, draftModel: draftModel, focusTitle: focusTitle
    app.views.main.show(postEditView)

  editPost: (id) ->
    post = app.util.loadPostModel id, true
    # Scroll to top of page.
    document.body.scrollTop = document.documentElement.scrollTop = 0
    postEditView = new PostEditView model: post
    app.views.main.show(postEditView)

  editDraft: (id) ->
    draftModel = app.collections.drafts.get(id)
    newPost = new Post
    newPost.collection = app.collections.posts
    newPost.set
      title: draftModel.get('title')
      body: draftModel.get('body')
      created: draftModel.get('created')
      changed: draftModel.get('changed')
    postEditView = new PostEditView model: newPost, draftModel: draftModel
    app.views.main.show(postEditView)

  search: (query = "") ->
    searchView = new SearchView collection: app.collections.search
    app.views.main.show(searchView)

    # Run query if there is one unless it's the same query as was run last time.
    query = decodeURIComponent query
    unless query is "" or query is app.collections.search.query_str
      app.collections.search.query(query)
    else
      app.collections.search.clear()
