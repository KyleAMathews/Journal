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

# Setup stores
require './stores/post_store'

# Kick off initial load of posts.
require('./actions/PostActions').load()

# Create a handy entrypoint into the various tools and datastores.
if window
  window._ = require 'underscore'
  window.moment = require 'moment'
  window.d3 = require 'd3'

  window.app = app = {}

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
