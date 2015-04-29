React = require 'react'
request = require 'superagent'
marked = require('marked')
moment = require 'moment'
Router = require('react-router')
Spinner = require 'react-spinkit'
Link = require('react-router').Link
_ = require 'underscore'
path = require 'path'
Reflux = require 'reflux'
gray = require 'gray-percentage'

Messages = require 'react-message'

PostStore = require '../stores/post_store'
LoadingStore = require '../stores/loading'

Button = require './Button'

module.exports = React.createClass
  displayName: 'Post'

  mixins: [
    Reflux.connect(LoadingStore, "loading"),
    Reflux.listenTo(PostStore, "getPost"),
    Router.Navigation
    Router.State
  ]

  getInitialState: ->
    {
      errors: []
    }

  componentDidMount: ->
    @getPost()

  render: ->
    if @state.errors.length > 0
      <Messages type="errors" messages={@state.errors} />
    else if not @state.post?.id
      return (
        <Spinner spinnerName="wave" fadeIn cssRequire />
      )
    else
      console.log @state
      return (
        <div onDoubleClick={@handleDblClick} className="post">
          <div
            style={{
              marginBottom: @props.rhythm(1.5)
            }}
          >
            <Link
              to="post-edit"
              params={{postId:@state.post.id}}
            >
              <Button {...@props}>
                Edit post
              </Button>
            </Link>
          </div>
          <div
            style={{
              color: gray(75)
              fontSize: '80%'
            }}
          >
            {moment(@state.post.created_at).format('dddd, MMMM Do YYYY, h:mma')}
          </div>
          <h1>
            {@state.post.title}
          </h1>
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
        @transitionTo('post', postId: path[2])
      else
        window.open e.target.href, '_blank'

  handleDblClick: ->
    @transitionTo('post-edit', postId: @state.post.id)

  getPost: ->
    PostStore.get(@getParams().postId).then (post) =>
      @setState post: post
