React = require 'react'
window.React = React
Route = require('react-nested-router').Route

App = require './react_components/app'

React.renderComponent((
  <Route handler={App} location="history" />
), document.body)
