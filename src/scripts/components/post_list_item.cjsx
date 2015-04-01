React = require 'react/addons'
TransitionGroup = React.addons.TransitionGroup
Link = require('react-router').Link
moment = require 'moment'
_ = require 'underscore'

module.exports = React.createClass
  displayName: 'PostListItem'

  render: ->
    <li
      style={{
        listStyle: 'none'
      }}
    >
      <Link
        to="post"
        params={{postId: @props.post.id}}
        style={{
          textDecoration: 'none'
        }}
      >
       {@props.post.title}
      </Link>
    </li>
