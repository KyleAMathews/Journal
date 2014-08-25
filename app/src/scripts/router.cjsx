# Load css first thing. It gets injected in the <head> in a <style> element by
# the Webpack style-loader.
require '../../public/main.css'

React = require 'react'
Route = require('react-router').Route
Routes = require('react-router').Routes

if window
  window.React = React

# Route handlers
App = require './components/app'
PostsIndex = require './components/posts_index'
Post = require './components/post'
PostEdit = require './components/post_edit'
NewPost = require './components/new_post'
Attribution = require './components/attribution'
Search = require './components/search'

# Dispatcher
Dispatcher = require './dispatcher'

# Stores
PostStore = require './stores/post_store'
AppStore = require './stores/app_store'
SearchStore = require './stores/search_store'

# Constants
PostConstants = require './constants/post_constants'
AppConstants = require './constants/app_constants'
SearchConstants = require './constants/search_constants'

# Transports
PostsAjax = require './transports/posts_ajax'
SearchAjax = require './transports/search_ajax'

# Kick off some fetching
Dispatcher.emit PostConstants.POSTS_FETCH

# Create a handy entrypoint into the various tools and datastores.
if window
  window._ = require 'underscore'
  window.moment = require 'moment'
  window.d3 = require 'd3'
  window.mori = require 'mori'

  window.app = app = {}
  app.transports = {}
  app.transports.PostsAjax = PostsAjax
  app.transports.SearchAjax = SearchAjax
  app.stores = {}
  app.stores.PostStore = PostStore
  app.stores.AppStore = AppStore
  app.stores.SearchStore = SearchStore
  app.constants = {}
  app.constants.PostConstants = PostConstants
  app.constants.AppConstants = AppConstants
  app.constants.SearchConstants = SearchConstants
  app.dispatcher = Dispatcher

React.renderComponent((
  <Routes>
    <Route handler={App}>
      <Route name="new-post" path="/posts/new" handler={NewPost} />
      <Route name="posts-index" path="/" handler={PostsIndex} />
      <Route name="post" path="/posts/:postId" handler={Post} />
      <Route name="post-edit" path="/posts/:postId/edit" handler={PostEdit} />
      <Route name="attributions" path="/attribution" handler={Attribution} />
      <Route name="search" path="/search" handler={Search} />
    </Route>
  </Routes>
), document.body)
