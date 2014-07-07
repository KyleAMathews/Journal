uuid = require('node-uuid')
MarkdownTextarea = require 'react-markdown-textarea'
Router = require('react-nested-router')
ReactTextarea = require 'react-textarea-autosize'
Spinner = require 'react-spinner'

Messages = require './messages'
Dispatcher = require '../dispatcher'
PostConstants = require '../constants/post_constants'
PostStore = require '../stores/post_store'
_ = require 'underscore'

module.exports = React.createClass
  displayName: 'NewPost'

  getInitialState: ->
    return {
      saving: false
      errors: []
      post:
        id: uuid.v1()
        title: ''
        body: ''
        created_at: new Date().toJSON()
    }

  componentDidMount: ->
    @refs.title.getDOMNode().focus()
    PostStore.on('add', 'new-post', (newPost) =>
      if newPost.temp_id is @state.post.id
        Router.transitionTo('post', postId: newPost.id)
    )
    Dispatcher.on 'POST_CREATE_ERROR', 'new-post', (data) =>
      @setState saving: false
      if data.error?.message?
        @setState errors: @state.errors.concat ["Saving failed. Message: '#{data.error.message}'"]
      else if data.body?.message?
        @setState errors: @state.errors.concat ["Saving failed. Message: '#{data.body.message}'"]

  componentWillUnmount: ->
    Dispatcher.releaseGroup('new-post')
    PostStore.releaseGroup('new-post')

  render: ->
    return (
      <div className="post-edit">
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
          saving={@state.saving}
          onSave={@handleSave}
          initialValue={@state.post.body} />
      </div>
    )

  handleTitleChange: ->
    post = _.extend @state.post, title: @refs.title.getDOMNode().value
    @setState post: post

  handleSave: (value) ->
    post = _.extend @state.post, body: value
    Dispatcher.emit PostConstants.POST_CREATE, post
    @setState saving: true
