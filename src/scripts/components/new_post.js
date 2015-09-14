import React from 'react'
import Relay from 'react-relay'
import _ from 'underscore'
import {History} from 'react-router'

import SaveMixin from '../mixins/save'
import CreatePostMutation from '../mutations/CreatePost'

const PostCreate = React.createClass({
  displayName: 'NewPost',

  mixins: [
    SaveMixin,
    History
  ],

  getInitialState() {
    return {
      post: {
        title: '',
        body: '',
        created_at: new Date().toJSON(),
      }
    }
  },

  onChange(cb) {
    let onSuccess = (response) => {
      console.log('new thing saved successfully', response)
      this.history.pushState(null, `/posts/${response.createPost.draftEdge.node.post_id}/edit`)
    }
    let onFailure = (transaction) => {
      let error = transaction.getError()
      console.log(transaction);
      console.log(error);
    }

    console.log(this.state.post, this.props)
    Relay.Store.update(new CreatePostMutation({
      viewer: this.props.viewer,
      title: this.state.post.title,
      body: this.state.post.body,
      created_at: this.state.post.created_at,
    }), {onFailure, onSuccess})
  },

  componentDidMount() {
    this.refs.title.focus()
    console.log(this.props);
  }
})

export default Relay.createContainer(PostCreate, {
  fragments: {
    viewer: () => Relay.QL`
      fragment on User {
        id
        ${CreatePostMutation.getFragment('viewer')}
        allDrafts(first:1) {
          edges {
            node {
              id
              post_id
            }
          }
        }
      }
    `
  }
});
