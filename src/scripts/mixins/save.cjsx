PostActions = require '../actions/PostActions'
Reflux = require 'reflux'
_ = require 'underscore'
Messages = require 'react-message'
Textarea = require 'react-textarea-autosize'
MarkdownTextarea = require 'react-markdown-textarea'
moment = require 'moment'
Spinner = require 'react-spinkit'
gray = require 'gray-percentage'

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
    {input, button} = require('react-simple-form-inline-styles')(@props.rhythm)
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
            onChange={@handleTitleChange}
            style={_.extend({}, input, {borderColor: 'transparent'})}
          />
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
          textareaStyle={_.extend(input, marginBottom: 0)}
          buttonStyle={_.extend({}, button, {
            float: 'left'
            marginTop: @props.rhythm(1)
            padding: "#{@props.rhythm(1/3)} #{@props.rhythm(2/3)}"
          })}
          deleteButtonStyle={_.extend({}, button, {
            float: 'right'
            marginTop: @props.rhythm(1)
            padding: "#{@props.rhythm(1/3)} #{@props.rhythm(2/3)}"
          })}
          navTabStyle={{
            fontSize: '15px'
            marginBottom: @props.rhythm(1/4)
          }}
          tabStyle={{
            borderRadius: 3
            cursor: 'pointer'
            display: 'inline-block'
            listStyle: 'none'
            marginRight: @props.rhythm(1/2)
            padding: "#{@props.rhythm(1/4)} #{@props.rhythm(1/2)}"
          }}
          tabActiveStyle={{
            background: gray(95, 'warm')
            border: "1px solid #{gray(75, 'warm')}"
            color: gray(35, 'warm')
            cursor: 'default'
            padding: "calc(#{@props.rhythm(1/4)} - 1px) #{@props.rhythm(1/2)}"
          }}
          previewStyle={{
            padding: @props.rhythm(3/4)
          }}
          spinnerOptions={
            fadeIn: true,
            spinnerName: "wave"
            className: "react-markdown-textarea__spinner"
          }
        />
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

  handleTitleChange: (e) ->
    post = _.extend @state.post, title: e.target.value
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

      unless @state.post.id?
        post = _.extend(
            {},
            @state.post,
            {
              latitude: @state.location.latitude
              longitude: @state.location.longitude
              draft: true
            }
        )
        PostActions.create post
      else
        PostActions.update @state.post

      @setState {
        savingDraft: true
      }

  handleSave: (value) ->
    post = _.extend(
        {},
        _.omit(@state.post, 'latitude', 'longitude'),
        {
          body: value
          draft: false
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
