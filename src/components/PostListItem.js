import React from 'react'
import { Link } from 'react-router'
import { typography } from '../typography'
const rhythm = typography.rhythm

export default React.createClass({
  displayName: 'PostListItem',

  render () {
    return (
      <li
        style={{
          listStyle: 'none',
          marginBottom: rhythm(1/4),
        }}
      >
        <Link
          to={`/posts/${this.props.post.post_id}`}
          style={{
            textDecoration: 'none',
          }}
        >
         {this.props.post.title}
        </Link>
      </li>
    )
  },
})
