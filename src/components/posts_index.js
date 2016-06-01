import React from 'react'
import moment from 'moment'
import { Link } from 'react-router'
import { typography } from '../typography'
const rhythm = typography.rhythm
import Relay from 'react-relay'

import Button from './Button'
import PostListItem from './PostListItem'

let loading = false

const PostsIndex = React.createClass({
  displayName: 'PostsIndex',

  getInitialState () {
    return {
      posts: [],
    }
  },

  componentDidMount () {
    window.addEventListener('scroll', this.distanceToBottom)
  },

  componentWillUnmount () {
    window.removeEventListener('scroll', this.distanceToBottom)
  },

  render () {
    const months = {}
    let posts = []
    // TODO refactor os map returns post instead of pushing onto array.
    this.props.viewer.allPosts.edges.map(function (node) {
      const post = node.node
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
        <PostListItem key={node.node.post_id} post={node.node} />
      )
      return
    })

    return (
      <div>
        <Link to="/posts/new">
          <Button {...this.props}>
            New post
          </Button>
        </Link>
        <ul style={{ margin: 0 }}>
          {posts}
        </ul>
      </div>
    )
  },

  distanceToBottom () {
    const body = document.body
    const html = document.documentElement

    const documentHeight = Math.max(body.scrollHeight, body.offsetHeight, html.clientHeight,
                          html.scrollHeight, html.offsetHeight)

    const windowHeight = window.innerHeight
    const scrollY = window.scrollY

    const distance = documentHeight - windowHeight - scrollY

    if (distance < 300 && loading === false) {
      loading = true
      this.props.relay.setVariables({
        first: this.props.relay.variables.first + 50,
      }, (state) => {
        if (state.done) loading = false
      })
    }
  },
})

export default Relay.createContainer(PostsIndex, {
  initialVariables: {
    first: 50,
  },

  fragments: {
    viewer: () => Relay.QL`
      fragment on User {
        id
        allPosts(first: $first) {
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
