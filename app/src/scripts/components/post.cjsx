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

Messages = require 'react-message'

PostStore = require '../stores/post_store'
LoadingStore = require '../stores/loading'

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
      # Upgrade photos for high density screens.
      body = @state.post.body
      if window.devicePixelRatio > 1.5
        re = new RegExp(/(\!\[.*\]\()(.*)(\))/g)
        amazon = new RegExp(/amazonaws.com\/pictures\//m)
        match = body.match(re)
        if match
          for pic in match
            # If this is one of our images on Amazon.
            if amazon.test pic
              link = pic.replace(re, "$2")
              split = link.split('/')
              # Rewrite image w/ @2x
              image = path.basename(link, path.extname(link))
              image = image + "@2x" + path.extname(link)
              split[split.length - 1] = image
              newLink = split.join('/')

              # Replace with retina image link
              body = body.replace(link, newLink)

      return (
        <div onDoubleClick={@handleDblClick} className="post">
          <Link className="button post__edit-button" to="post-edit" params={{postId:@state.post.id}} ><span className="icon-flat-pencil" />Edit post</Link>
          <span className="post__date">{moment(@state.post.created_at).format('dddd, MMMM Do YYYY, h:mma')}</span>
          <h1 className="post__title">{@state.post.title}</h1>
          <div onClick={@handleClick} dangerouslySetInnerHTML={__html:marked(body, smartypants:true)}></div>
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
