React = require 'react'
Link = require('react-nested-router').Link
request = require 'superagent'

module.exports = React.createClass
  displayName: 'App'
  render: ->
    <div>
      <div><Link to="index">Home</Link></div>
      {@props.activeRoute}
    </div>
