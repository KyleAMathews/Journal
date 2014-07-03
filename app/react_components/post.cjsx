React = require 'react'
request = require 'superagent'
marked = require('marked')
moment = require 'moment'
Router = require('react-nested-router')
Spinner = require 'react-spinner'
Link = require('react-nested-router').Link
_ = require 'underscore'

postsDAO = require '../posts'

module.exports = React.createClass
  getInitialState: ->
    return {
      title: ''
      body: ''
      loading: true
    }

  componentDidMount: ->
    # Ensure we're at the top of the page.
    scroll(0,0)

    # Fetch the post data.
    postsDAO.getPost @props.params.postId, (post) =>
      post = _.extend post, loading: false
      @setState post

  # Handle clicks on interlinks between posts.
  handleClick: (e) ->
    e.preventDefault()
    # Ignore unless the click was on an A element.
    if e.target.nodeName is "A"
      path = e.target.pathname?.split('/')
      if path[1] is "posts" and path[2]?
        Router.transitionTo('post', postId: path[2])

  handleDblClick: ->
    Router.transitionTo('post-edit', postId: @state.id)

  render: ->
    if @state.loading
      return (
        <Spinner />
      )
    else
      return (
        <div onDoubleClick={@handleDblClick} className="post">
          <Link className="button post__edit-button" to="post-edit" postId={@state.id} >Edit post</Link>
          <h1 className="post__title">{@state.title}</h1>
          <small>{moment(@state.created_at).format('dddd, MMMM Do YYYY, h:mma')}</small>
          <div onClick={@handleClick} dangerouslySetInnerHTML={__html:marked(@state.body, smartypants:true)}></div>
        </div>
      )
