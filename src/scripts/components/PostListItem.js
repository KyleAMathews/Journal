import React from 'react'
import { Link } from 'react-router'

export default React.createClass({
  displayName: 'PostListItem',

  render() {
    return (
      <li
        style={{
          listStyle: 'none'
        }}
      >
        <Link
          to={`/posts/${this.props.post.post_id}`}
          style={{
            textDecoration: 'none'
          }}
        >
         {this.props.post.title}
        </Link>
      </li>
    )
  }
})
