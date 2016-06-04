import React from 'react'
import Relay from 'react-relay'
import { EditorState } from 'draft-js'
import { withRouter } from 'react-router'

import SaveMixin from '../mixins/save'
import CreatePostMutation from '../mutations/CreatePost'

// TODO, create new post as soon as tab out of the title
// area.
//
// Actually, just get rid of this and create
// a new post right off and navigate there
// from the home screen.

const PostCreate = React.createClass({
  displayName: 'NewPost',

  mixins: [
    SaveMixin,
  ],

  getInitialState () {
    return {
      post: {
        title: '',
        body: '',
        rteBody: EditorState.createEmpty(),
        created_at: new Date().toJSON(),
      },
    }
  },

  onChange (cb) {
    let onSuccess = (response) => {
      console.log('new thing saved successfully', response)
      this.props.router.push( `/posts/${response.createPost.draftEdge.node.post_id}/edit`)
    }
    let onFailure = (transaction) => {
      let error = transaction.getError()
      console.log(transaction)
      console.log(error)
    }

    console.log(this.state.post, this.props)
    Relay.Store.commitUpdate(new CreatePostMutation({
      viewer: this.props.viewer,
      title: this.state.post.title,
      body: this.state.post.body,
      created_at: this.state.post.created_at,
    }), { onFailure, onSuccess })
  },

  componentDidMount () {
    this.refs.title.focus()
    console.log(this.props)
  },
})

export default Relay.createContainer(withRouter(PostCreate), {
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
    `,
  },
})
