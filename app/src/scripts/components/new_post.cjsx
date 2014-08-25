uuid = require('node-uuid')
MarkdownTextarea = require 'react-markdown-textarea'
Router = require('react-router')
ReactTextarea = require 'react-textarea-autosize'

Messages = require './messages'
Dispatcher = require '../dispatcher'
PostConstants = require '../constants/post_constants'
PostStore = require '../stores/post_store'
AppStore = require '../stores/app_store'
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
        latitude: AppStore.get('coordinates')?.latitude
        longitude: AppStore.get('coordinates')?.longitude
        deleted: false
        starred: false
    }

  componentDidMount: ->
    @refs.title.getDOMNode().focus()
    PostStore.on('add', 'new-post', (newPost) =>
      if newPost.temp_id is @state.post.id
        # Post saved successfully. Destroy any errors and move to post view.
        Dispatcher.emit PostConstants.POST_ERROR_DESTROY, @state.post.id
        Router.transitionTo('post', postId: newPost.id)
    )
    PostStore.on('change_error', 'new-post', =>
      errors = PostStore.getErrorById(@state.post.id)
      unless _.isEmpty(errors)
        @setState saving: false
        # Look at each class of errors in turn.
        for errorType, errorTypeErrors of errors
          # Loop through errors and add them to the errors message array.
          for data in errorTypeErrors
            message = "Saving failed. Message: \"#{data.error}\""
            unless (@state.errors.some (val) -> val is message)
              @setState errors: @state.errors.concat [message]
    )

  componentWillUnmount: ->
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
    @setState {
      saving: true
      errors: []
    }
