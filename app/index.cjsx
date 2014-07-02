React = require 'react'
window.React = React
Route = require('react-nested-router').Route

App = require './react_components/app'
Index = require './react_components/index'
Post = require './react_components/post'
eventBus = require './event_bus'

# Assign some convenient js libraries to the Window
if window?
  window._ = require 'underscore'

Posts = require './posts'

React.renderComponent((
  <Route handler={App} location="history">
    <Route name="index" path="/" handler={Index} />
    <Route name="post" path="/posts/:postId" handler={Post} />
  </Route>
), document.body)
