import React, { Component } from 'react'
import moment from 'moment'
import { Link } from 'react-router'
import { typography } from '../typography'
const rhythm = typography.rhythm
import Relay from 'react-relay'

import PostListItem from './PostListItem'

const DraftsIndex = React.createClass({
  displayName: 'DraftsIndex',

  render () {
    var months = {}
    var posts = []
    this.props.viewer.allDrafts.edges.map(function (node) {
      let post = node.node
      let month = moment(post.created_at).format('MMMM YYYY')
      if (!months[month]) {
        posts.push(
          <h2
            style={{
              marginTop: rhythm(1),
            }}
            key={month}
          >
            {month}
          </h2>
        )
      }
      months[month] = true

      posts.push(
        <PostListItem key={node.node.post_id} post={node.node}></PostListItem>
      )
      return
    })

    return (
      <div className="posts-index">
        <h1>Drafts</h1>
        <ul className="posts-index__list">
          {posts}
        </ul>
      </div>
    )
  },
})

export default Relay.createContainer(DraftsIndex, {
  initialVariables: {
    first: 100,
  },

  fragments: {
    viewer: () => Relay.QL`
      fragment on User {
        id
        allDrafts(first: $first) {
          edges {
            node {
              post_id
              title
              body
              created_at
            }
          }
        }
      }
    `,
  },
})
