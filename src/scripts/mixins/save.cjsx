PostActions = require '../actions/PostActions'
Reflux = require 'reflux'
_ = require 'underscore'
Messages = require 'react-message'
Textarea = require 'react-textarea-autosize'
MarkdownTextarea = require 'react-markdown-textarea'
moment = require 'moment'
Spinner = require 'react-spinkit'

LocationStore = require '../stores/location'

module.exports =
  mixins: [
    Reflux.connect(LocationStore, 'location')
  ]

  getInitialState: ->
    return {
      saving: false
      actionListeners: []
      errors: []
    }

  componentWillUpdate: (nextProps, nextState) ->
    if nextState.location?.latitude? and not nextState.post.latitude
      nextState.post = _.extend nextState.post, nextState.location

  componentDidMount: ->
    @debouncedSaveDraft = _.debounce @saveDraft, 1500

    # Subscribe to action updates.
    @state.actionListeners.push PostActions.createComplete.listen(@onCreateComplete)
    @state.actionListeners.push PostActions.updateComplete.listen(@onUpdateComplete)
    @state.actionListeners.push PostActions.deleteComplete.listen(@onDeleteComplete)
    @state.actionListeners.push PostActions.createError.listen(@handleHTTPError)
    @state.actionListeners.push PostActions.updateError.listen(@handleHTTPError)
    @state.actionListeners.push PostActions.deleteError.listen(@handleHTTPError)

  componentWillUnmount: ->
    for unsubscribeFunc in @state.actionListeners
      unsubscribeFunc()

  render: ->
    unless @state.post?
      return (
        <Spinner spinnerName="wave" fadeIn cssRequire />
      )
    else
      <div className="post-edit">
        <Messages type="error" messages={@state.errors} />
        <h1>
          <Textarea
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
          deleteButton=true
          onDelete={@handleDelete}
          saving={@state.saving}
          onChange={@handleBodyChange}
          onSave={@handleSave}
          initialValue={@state.post.body}
          spinner={Spinner}
          spinnerOptions={
            fadeIn: true,
            spinnerName: "wave"
            className: "react-markdown-textarea__spinner"
          } />
        <div
          style={{
            bottom: '10px'
            color: 'lightgray'
            left: '10px'
            position: 'fixed'
          }}>
          {if @state.unsavedChanges?
            if @state.unsavedChanges
              "Not saved"
            else
              "Saved"
          }
        </div>
      </div>

  handleTitleChange: ->
    post = _.extend @state.post, title: @refs.title.getDOMNode().value
    @setState {
      post: post
      unsavedChanges: true
    }

    @debouncedSaveDraft()

  handleBodyChange: (value) ->
    post = _.extend @state.post, body: value
    @setState {
      post: post
      unsavedChanges: true
    }

    @debouncedSaveDraft()

  saveDraft: ->
    # Only save drafts if it is a draft
    # and there's a title/body
    if @state.post.title isnt '' and
        @state.post.body isnt '' and
        not @state.savingDraft and
        @state.post.draft isnt false

      unless @state.post.id
        PostActions.create @state.post
      else
        PostActions.update @state.post

      @setState {
        savingDraft: true
      }

  handleSave: (value) ->
    post = _.extend(
        @state.post,
        {
          body: value
          latitude: @state.location.latitude
          longitude: @state.location.longitude
        }
    )

    if post.title is "" or post.body is ""
      @setState errors: @state.errors.concat ["Missing title or body"]
    else
      @setState {
        saving: true
        errors: []
      }

      PostActions.update post

  handleDelete: ->
    PostActions.delete(@state.post)

  handleHTTPError: (res) ->
    @setState {
      savingDraft: false
      saving: false
      errors: [res.error.message]
    }

  onUpdateComplete: (res) ->
    @setState {
      savingDraft: false
      unsavedChanges: false
    }

    # Since the save button was clicked, transition to the post view.
    if @state.saving
      @transitionTo('post', postId: @state.post.id)

  onDeleteComplete: ->
    @transitionTo('posts-index')

  onCreateComplete: (res) ->
    id = res.body.id
    post = _.extend @state.post, res.body

    @setState {
      savingDraft: false
      unsavedChanges: false
      post: post
    }

    # Since the save button was clicked, transition to the post view.
    if @state.saving
      @transitionTo('post', postId: post.id)
