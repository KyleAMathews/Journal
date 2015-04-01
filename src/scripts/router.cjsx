React = require 'react'
Router = require('react-router')
Route = require('react-router').Route

if window
  window.React = React

# Route handlers
Styleguide = require 'react-html-elements-styleguide'
App = require './components/app'
PostsIndex = require './components/posts_index'
DraftsIndex = require './components/drafts_index'
Post = require './components/post'
PostEdit = require './components/post_edit'
NewPost = require './components/new_post'
Attribution = require './components/attribution'
Search = require './components/SearchController'

Typography = require 'typography'
typography = new Typography({
  headerFontFamily: '"Clear Sans", "Helvetica Neue", Helvetica, Arial, sans-serif'
  headerGray: 15
  bodyGray: 30
  bodyFontFamily: '"Linux Libertine", Georgia, sans-serif'
  baseFontSize: "20px"
  baseLineHeight: "26px"
  modularScales: [
    'major third'
    ['768px', 'minor third']
  ]
})
typography.injectStyles()

# Setup stores
require './stores/post_store'
require './stores/drafts_store'
require './stores/location'

# Kick off initial load of posts.
require('./actions/PostActions').load()

# Create a handy entrypoint into the various tools and datastores.
if window
  window._ = require 'underscore'
  window.moment = require 'moment'
  window.d3 = require 'd3'

  window.app = app = {}

routes = (
  <Route handler={App}>
    <Route name="posts-index" path="/" handler={PostsIndex} />
    <Route name="drafts-index" path="/drafts" handler={DraftsIndex} />
    <Route name="new-post" path="/posts/new" handler={NewPost} />
    <Route name="post" path="/posts/:postId" handler={Post} />
    <Route name="post-edit" path="/posts/:postId/edit" handler={PostEdit} />
    <Route name="styleguide" handler={Styleguide} path="/styleguide" />
    <Route name="attributions" path="/attribution" handler={Attribution} />
    <Route name="search" path="/search" handler={Search} />
  </Route>
)

Router.run(routes, (Handler) ->
  React.render(<Handler typography={typography} rhythm={typography.rhythm} />, document.getElementById('mount-point'))
)
