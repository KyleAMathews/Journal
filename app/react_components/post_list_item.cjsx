React = require 'react/addons'
TransitionGroup = React.addons.TransitionGroup
Link = require('react-nested-router').Link
moment = require 'moment'
_ = require 'underscore'

module.exports = React.createClass
  displayName: 'PostListItem'

  render: ->
    <li className="posts-index__list__item"><Link to="post" postId={@props.post.id}>{@props.post.title}</Link></li>
