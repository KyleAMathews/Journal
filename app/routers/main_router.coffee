{PostsView} = require 'views/posts_view'
{PostView} = require 'views/post_view'
{PostEditView} = require 'views/post_edit_view'
Post = require 'models/post'
DraftsView = require 'views/drafts_view'
SearchView = require 'views/search_view'

class exports.MainRouter extends Backbone.Router

  routes:
    '': 'home'
    'node/:id': 'post'
    'posts/new': 'newPost'
    'node/:id/edit': 'editPost'
    'drafts': 'drafts'
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

  newPost: (focusTitle = false, replaceUrl = false) ->
    if replaceUrl
      app.router.navigate('posts/new')

    # Scroll to top of page.
    document.body.scrollTop = document.documentElement.scrollTop = 0
    newPost = new Post {}, collection: app.collections.posts
    newPost.set created: new Date().toISOString()
    postEditView = new PostEditView model: newPost, focusTitle: focusTitle, newPost: true
    app.views.main.show(postEditView)

  editPost: (id) ->
    post = app.util.loadPostModel id, true
    # Scroll to top of page.
    document.body.scrollTop = document.documentElement.scrollTop = 0
    postEditView = new PostEditView model: post
    app.views.main.show(postEditView)

  drafts: ->
    draftsView = new DraftsView collection: app.collections.posts
    app.views.main.show(draftsView)

  search: (query = "", reset = false) ->
    searchView = new SearchView collection: app.collections.search
    app.views.main.show(searchView)

    # Run query if there is one unless it's the same query as was run last time.
    query = decodeURIComponent query
    unless query is app.collections.search.query_str
      app.collections.search.query(query)
