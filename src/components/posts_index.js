import React, { Component } from 'react'
import moment from 'moment'
import { Link } from 'react-router'
import { typography } from '../typography'
const rhythm = typography.rhythm
import Relay from 'react-relay'

import Button from './Button'
import PostListItem from './PostListItem'

var loading = false

const PostsIndex = React.createClass({
  displayName: 'PostsIndex',

  getInitialState() {
    return {
      posts: []
    }
  },

  componentDidMount() {
    window.addEventListener('scroll', this.distanceToBottom)
  },

  componentWillUnmount() {
    window.removeEventListener('scroll', this.distanceToBottom)
  },

  render() {
    var months = {};
    var posts = [];
    this.props.viewer.allPosts.edges.map(function(node) {
      let post = node.node;
      let month = moment(post.created_at).format('MMMM YYYY');
      if(!months[month]) {
        posts.push (
          <h2
            style={{
              marginTop: rhythm(1)
            }}
            key={month}
          >
            {month}
          </h2>
        )
      }
      months[month] = true

      posts.push (
        <PostListItem key={node.node.post_id} post={node.node}></PostListItem>
      )
      return
    })

    return (
      <div>
         <Link to='/posts/new'>
           <Button {...this.props}>
             New post
           </Button>
         </Link>
        <ul style={{margin: 0}}>
          {posts}
        </ul>
      </div>
    )
  },

  distanceToBottom() {
    let body = document.body,
        html = document.documentElement;

    let documentHeight = Math.max(body.scrollHeight, body.offsetHeight, html.clientHeight,
                          html.scrollHeight, html.offsetHeight);

    let windowHeight = window.innerHeight;
    let scrollY = window.scrollY;

    let distance = documentHeight - windowHeight - scrollY

    if (distance < 300 && loading === false) {
      loading = true;
      this.props.relay.setVariables({
        first: this.props.relay.variables.first + 50
      }, function(state) {
        if (state.done) loading = false
      })
    }
  }
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
    `
  }
});
