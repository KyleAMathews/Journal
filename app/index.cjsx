React = require 'react'
window.React = React
Route = require('react-nested-router').Route

App = require './react_components/app'
Index = require './react_components/index'
Post = require './react_components/post'
PostEdit = require './react_components/post_edit'
Attribution = require './react_components/attribution'

eventBus = require './event_bus'

# Assign some convenient js libraries to the Window
if window?
  window._ = require 'underscore'

Posts = require './posts'

React.renderComponent((
  <Route handler={App} location="history">
    <Route name="index" path="/" handler={Index} />
    <Route name="post" path="/posts/:postId" handler={Post} />
    <Route name="post-edit" path="/posts/:postId/edit" handler={PostEdit} />
    <Route name="attributions" path="/attribution" handler={Attribution} />
  </Route>
), document.body)
