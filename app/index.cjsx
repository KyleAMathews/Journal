React = require 'react'
window.React = React
Route = require('react-nested-router').Route

App = require './react_components/app'
Index = require './react_components/index'
Post = require './react_components/post'
eventBus = require './event_bus'

React.renderComponent((
  <Route handler={App} location="history">
    <Route name="index" path="/" handler={Index} />
    <Route name="post" path="/posts/:postId" handler={Post} />
  </Route>
), document.body)
