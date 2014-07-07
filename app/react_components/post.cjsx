React = require 'react'
request = require 'superagent'
marked = require('marked')
moment = require 'moment'
Router = require('react-nested-router')
Spinner = require 'react-spinner'
Link = require('react-nested-router').Link
_ = require 'underscore'

Messages = require './messages'
PostStore = require '../stores/post_store'
Dispatcher = require '../dispatcher'

module.exports = React.createClass
  getInitialState: ->
    state =
      post: post = PostStore.get(@props.params.postId)
      errors: []
      loading: false

    if post
      return state
    else
      state.post = {}
      state.loading = true
      return state

  componentDidMount: ->
    # Ensure we're at the top of the page.
    scroll(0,0)

    PostStore.on('change', "post", =>
      if @state.loading and PostStore.get(@props.params.postId)
        @setState {
          post: PostStore.get(@props.params.postId)
          loading: false
        }
    )

    Dispatcher.on 'POST_FETCH_ERROR', "post", (data) =>
      if data.id is parseInt(@props.params.postId, 10)
        @setState {
          loading: false
          errors: @state.errors.concat [data.message.message]
        }

  componentWillUnmount: ->
    PostStore.releaseGroup("post")
    Dispatcher.releaseGroup("post")

  render: ->
    if @state.loading
      return (
        <Spinner />
      )
    else if @state.errors.length > 0
      <Messages type="errors" messages={@state.errors} />
    else
      return (
        <div onDoubleClick={@handleDblClick} className="post">
          <Link className="button post__edit-button" to="post-edit" postId={@state.post.id} ><span className="icon-flat-pencil" />Edit post</Link>
          <h1 className="post__title">{@state.post.title}</h1>
          <small>{moment(@state.post.created_at).format('dddd, MMMM Do YYYY, h:mma')}</small>
          <div onClick={@handleClick} dangerouslySetInnerHTML={__html:marked(@state.post.body, smartypants:true)}></div>
        </div>
      )

  # Handle clicks on interlinks between posts.
  handleClick: (e) ->
    e.preventDefault()
    # Ignore unless the click was on an A element.
    if e.target.nodeName is "A"
      path = e.target.pathname?.split('/')
      if path[1] is "posts" and path[2]?
        Router.transitionTo('post', postId: path[2])
      else
        window.open e.target.href, '_blank'

  handleDblClick: ->
    Router.transitionTo('post-edit', postId: @state.post.id)

