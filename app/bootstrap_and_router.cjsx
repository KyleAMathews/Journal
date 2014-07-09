React = require 'react'
Route = require('react-nested-router').Route

if window
  window.React = React

# Route handlers
App = require './react_components/app'
PostsIndex = require './react_components/posts_index'
Post = require './react_components/post'
PostEdit = require './react_components/post_edit'
NewPost = require './react_components/new_post'
Attribution = require './react_components/attribution'
Search = require './react_components/search'

# Dispatcher
Dispatcher = require './dispatcher'

# Stores
PostStore = require './stores/post_store'
AppStore = require './stores/app_store'

# Constants
PostConstants = require './constants/post_constants'
AppConstants = require './constants/app_constants'

# Transports
PostsAjax = require './transports/posts_ajax'

# Kick off some fetching
Dispatcher.emit PostConstants.POSTS_FETCH

# Create a handy entrypoint into the various tools and datastores.
if window
  window._ = require 'underscore'
  window.moment = require 'moment'
  window.d3 = require 'd3'

  window.app = app = {}
  app.transports = {}
  app.transports.PostsAjax = PostsAjax
  app.stores = {}
  app.stores.PostStore = PostStore
  app.stores.AppStore = AppStore
  app.constants = {}
  app.constants.PostConstants = PostConstants
  app.constants.AppConstants = AppConstants
  app.dispatcher = Dispatcher

React.renderComponent((
  <Route handler={App} location="history">
    <Route name="new-post" path="/posts/new" handler={NewPost} />
    <Route name="posts-index" path="/" handler={PostsIndex} />
    <Route name="post" path="/posts/:postId" handler={Post} />
    <Route name="post-edit" path="/posts/:postId/edit" handler={PostEdit} />
    <Route name="attributions" path="/attribution" handler={Attribution} />
    <Route name="search" path="/search" handler={Search} />
  </Route>
), document.body)
