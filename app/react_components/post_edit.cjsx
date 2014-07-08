React = require 'react'
request = require 'superagent'
marked = require('marked')
moment = require 'moment'
_ = require 'underscore'
Router = require('react-nested-router')
MarkdownTextarea = require 'react-markdown-textarea'
ReactTextarea = require 'react-textarea-autosize'
Spinner = require 'react-spinner'

Messages = require './messages'
PostStore = require '../stores/post_store'
PostConstants = require '../constants/post_constants'
Dispatcher = require '../dispatcher'

module.exports = React.createClass
  getInitialState: ->
    state = {
      post: post = PostStore.get(@props.params.postId)
      errors: []
      loading: false
      saving: false
    }

    if post
      return state
    else
      state.post = {}
      state.loading = true
      return state


  componentDidMount: ->
    # Ensure we're at the top of the page.
    scroll(0,0)

    PostStore.on('change', 'post-edit', =>
      # We're waiting for our post to be loaded.
      # Let's check if it's here.
      if @state.loading and PostStore.get(@props.params.postId)
        @setState {
          post: PostStore.get(@props.params.postId)
          loading: false
        }
      # We're waiting for our post to be saved,
      # let's see if that's happened.
      if @state.saving
        post = PostStore.get(@props.params.postId)
        if post.updated_at > @state.post.updated_at
          # Post was saved successfully
          Dispatcher.emit PostConstants.POST_ERROR_DESTROY, @state.post.id
          Router.transitionTo('post', postId: @state.post.id)
    )

    PostStore.on('change_error', 'post-edit', =>
      errors = PostStore.getErrorById(@props.params.postId)
      unless _.isEmpty(errors)
        @setState saving: false
        # Look at each class of errors in turn.
        for errorType, errorTypeErrors of errors
          # If we can't load the post to edit, just go back to posts-index.
          if errorType is "POST_FETCH_ERROR"
            Router.transitionTo('posts-index')
          # Loop through errors and add them to the errors message array.
          for data in errorTypeErrors
            message = "Saving failed. Message: \"#{data.error}\""
            unless (@state.errors.some (val) -> val is message)
              @setState errors: @state.errors.concat [message]
    )

  componentWillUnmount: ->
    PostStore.releaseGroup('post-edit')

  componentWillUpdate: ->
    setTimeout((->
      jQuery('textarea').trigger('autosize.resize')
    ), 0)

  render: ->
    if @state.loading
      return (
        <Spinner />
      )
    else
      return (
        <div className="post-edit" onClick={@handleClick}>
          <Messages type="errors" messages={@state.errors} />
          <h1>
            <ReactTextarea
              placeholder="New title for post"
              rows=1
              className="post-edit__title"
              ref="title"
              autosize
              value={@state.post.title}
              onChange={@handleTitleChange} />
          </h1>
          <MarkdownTextarea
            placeholder="The body of your post"
            rows=4
            onSave={@handleSave}
            saving={@state.saving}
            initialValue={@state.post.body} />
        </div>
      )

  handleSave: (value) ->
    post = @state.post
    post.body = value
    delete post.temp_id

    # Validate
    if post.title is "" or post.body is ""
      @setState errors: @state.errors.concat ["Missing title or body"]
    else
      Dispatcher.emit PostConstants.POST_UPDATE, post
      @setState saving: true

  handleTitleChange: ->
    post = _.extend @state.post, title: @refs.title.getDOMNode().value
    @setState post

  handleClick: (e) ->
    e.preventDefault()
    # Ignore unless the click was on an A element.
    if e.target.nodeName is "A"
      window.open(e.target.href, '_blank')
