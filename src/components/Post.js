import React from 'react'
import { Link } from 'react-router'
import moment from 'moment'
import gray from 'gray-percentage'
import Relay from 'react-relay'
import marked from 'marked'

import { typography } from '../typography'
const rhythm = typography.rhythm
import Button from './Button'

const Post = React.createClass({
  displayName: 'Post',

  componentDidMount () {
    window.scroll(0, 0)
  },

  render () {
    console.log(this.props)
    // if @state.errors.length > 0
      // <Messages type="errors" messages={@state.errors} />
    // else if not @state.post?.id
      // return (
        // <Spinner spinnerName="wave" fadeIn cssRequire />
      // )
    // else
      // console.log @state
    return (
      <div onDoubleClick={this.handleDblClick} className="post">
        <div
          style={{
            marginBottom: rhythm(1.5),
          }}
        >
          <Link
            to={`/posts/${this.props.node.post_id}/edit`}
            params={{ postId: this.props.node.post_id }}
          >
            <Button {...this.props}>
              Edit post
            </Button>
          </Link>
        </div>
        <div
          style={{
            color: gray(75),
            fontSize: '80%',
          }}
        >
          {moment(this.props.node.created_at).format('dddd, MMMM Do YYYY, h:mma')}
        </div>
        <h1>
          {this.props.node.title}
        </h1>
        <div
          dangerouslySetInnerHTML={{
            __html: marked(this.props.node.body, { smartypants: true }),
          }}
        />
      </div>
    )
  },

  // Handle clicks on interlinks between posts.
  // handleClick: (e) ->
    // e.preventDefault()
    // # Ignore unless the click was on an A element.
    // if e.target.nodeName is "A"
      // path = e.target.pathname?.split('/')
      // if path[1] is "posts" and path[2]?
        // @transitionTo('post', postId: path[2])
      // else
        // window.open e.target.href, '_blank'

  handleDblClick () {
    this.history.pushState(null, `/posts/${this.props.node.post_id}/edit`)
  },
})

export default Relay.createContainer(Post, {
  initialVariables: {
    post_id: null,
    id: btoa('Post:1'),
  },

  prepareVariables: (prevVariables) => ({
    ...prevVariables,
    id: btoa(`Post:${prevVariables.post_id}`),
    post_id: parseInt(prevVariables.post_id, 10),
  }),

  fragments: {
    node: () => Relay.QL`
      fragment on Post {
        post_id
        title
        body
        created_at
      }
    `,
  },
})
