import React from 'react'
import ReactDOM from 'react-dom'
import Relay from 'react-relay'
import _ from 'underscore'
import {History} from 'react-router'

import SaveMixin from '../mixins/save'
import EditPostMutation from '../mutations/EditPost'
import SavePostMutation from '../mutations/SavePost'

// TODO simplify things.
// Have a SavePostMutation that just updates title/body/updated_at
// as well as a PublishPostMutation which changes draft from true
// to false.
//
// Also need a DeletePostMutation and UndeletePostMutation at some
// point.

const PostEdit = React.createClass({
  displayName: 'PostEdit',

  getInitialState() {
    return {
      post: {
        title: this.props.node.title,
        body: this.props.node.body,
        created_at: this.props.node.created_at,
        draft: this.props.node.draft
      }
    }
  },

  mixins: [
    History,
    SaveMixin
  ],

  componentDidMount() {
    const element = ReactDOM.findDOMNode(this.refs.markdown.refs.textarea)
    element.focus()
    element.setSelectionRange(element.value.length,element.value.length)
  },

  onChange(cb) {
    // Back out if node isn't mounted.
    if (!this.isMounted()) { return }

    this.setState({
      unsavedChanges: true,
      errors: []
    })

    // Success/Failure handlers
    let onSuccess = (response) => {
      this.setState({unsavedChanges: false})
      console.log(response)
      if (cb) { cb() }
    }
    let onFailure = (transaction) => {
      let error = transaction.getError()
      this.setState({
        errors: [error.message]
      })
    }

    if (this.state.saveFromDraft === true) {
      console.log("saving post from draft to published");
      Relay.Store.update(new SavePostMutation({
        post: this.props.node,
        viewer: this.props.viewer,
        id: this.props.node.id,
        title: this.state.post.title,
        body: this.state.post.body,
      }), {onFailure, onSuccess})
    }
    else {
      console.log("editing saving");
      Relay.Store.update(new EditPostMutation({
        viewer: this.props.viewer,
        post: this.props.node,
        id: this.props.node.id,
        title: this.state.post.title,
        body: this.state.post.body,
      }), {onFailure, onSuccess})
    }
  },
})

export default Relay.createContainer(PostEdit, {
  initialVariables: {
    post_id: null,
    id: btoa('Post:' + 1),
  },

  prepareVariables: prevVariables => {
    return {
      ...prevVariables,
      id: btoa('Post:' + prevVariables.post_id),
      post_id: parseInt(prevVariables.post_id, 10)
    }
  },

  fragments: {
    node: () => Relay.QL`
      fragment on Post {
        id
        post_id
        title
        body
        created_at
        draft
        ${EditPostMutation.getFragment('post')}
        ${SavePostMutation.getFragment('post')}
      }
    `,
    viewer: () => Relay.QL`
      fragment on User {
        id
        ${SavePostMutation.getFragment('viewer')}
        allDrafts(first:5) {
          edges {
            node {
              id
              post_id
              title
              body
              created_at
            }
          }
        }
        allPosts(first:5) {
          edges {
            node {
              id
              post_id
              title
              body
              created_at
            }
          }
        }
      }
    `,
  }
});
        //allDrafts(first:5) {
          //edges {
            //node {
              //id
              //post_id
              //title
            //}
          //}
        //}
        //allPosts(first:5) {
          //edges {
            //node {
              //id
              //post_id
              //title
            //}
          //}
        //}
