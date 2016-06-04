#PostActions = require '../actions/PostActions'
React = require 'react'
ReactDOM = require 'react-dom'
_ = require 'underscore'
Messages = require 'react-message'
Textarea = require('react-textarea-autosize').default
#MarkdownTextarea = require 'react-markdown-textarea'
moment = require 'moment'
Spinner = require 'react-spinkit'
gray = require 'gray-percentage'
raf = require 'raf'
#RichTextEditor = require('react-rte').default
#MarkupEditor = require('react-markup-editor')
{Editor, EditorState, ContentState} = require 'draft-js'
assign = require 'object-assign'

Button = require '../components/Button'

{typography} = require '../typography'
rhythm = typography.rhythm

#LocationStore = require '../stores/location'
#
# TODO consolidate changes into @onChange() and @onDelete calls
# post_edit/post_new would use PostCreate/PostUpsert/PostDelete mutations.

module.exports =
  getInitialState: ->
    return {
      saving: false
      actionListeners: []
      errors: []
    }

  componentWillUpdate: (nextProps, nextState) ->
    if nextState?.location?.latitude? and not nextState?.post?.latitude
      nextState.post = _.extend nextState.post, nextState.location

  componentDidMount: ->
    @debouncedSaveDraft = _.debounce @saveDraft, 1500

  componentWillUnmount: ->
    for unsubscribeFunc in @state.actionListeners
      unsubscribeFunc()

  render: ->
    {input, button} = require('react-simple-form-inline-styles')(rhythm)
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
            style={
              _.extend(
                {},
                input,
                {
                  borderColor: 'transparent'
                  marginBottom: 0
                }
              )
            }
          />
        </h1>
        <div
          style={_.extend({}, input)}
          ref="markdown"
        >
          <Editor
            editorState={@state.post.rteBody}
            stripPastedStyles
            spellCheck
            onChange={@rteOnChange}
          />
        </div>
        <Button
          onClick={@handleSave}
        >
          Save
        </Button>
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

  rteOnChange: (value) ->
    @setState(
      post: assign(
        {},
        @state.post,
        {
          rteBody: value
          body: value.getCurrentContent().getPlainText()
        }
      )
    )
    @debouncedSaveDraft()
    raf(=> @scrollWindow())

  handleTitleChange: (e) ->
    post = _.extend {}, @state.post, title: e.target.value
    @setState {
      post: post
      unsavedChanges: true
    }

    @debouncedSaveDraft()

  handleBodyChange: (value) ->
    raf(=> @scrollWindow())

    post = _.extend {}, @state.post, body: value
    @setState {
      post: post
      unsavedChanges: true
    }

    @debouncedSaveDraft()

  scrollWindow: ->
    textarea = ReactDOM.findDOMNode(@refs.markdown)

    toBottomWindow = -> window.scrollY + window.innerHeight
    toBottomElement = -> textarea.offsetHeight + textarea.offsetTop
    distanceToBottom = toBottomWindow() - toBottomElement()
    if -100 < distanceToBottom < 100
      window.scrollTo(0, window.scrollY + 200)

  saveDraft: ->
    console.log @state
    # Only save and there's a title/body
    if @state.post.title isnt '' and
        @state.post.body isnt ''

      @onChange()

  handleSave: (value) ->
    console.log "SAVE ME!!"
    # If the post is a draft and we're saving, this means it's published now
    # or not a draft any longer.
    #
    # If it's not a draft i.e. published already, just do normal save.
    if @state.post.draft
      saveFromDraft = true
    else
      saveFromDraft = false

    @setState({
      saveFromDraft: saveFromDraft
    }, =>
      @onChange =>
        console.log "SAVED :)"
        console.log @
        @props.router.push("/posts/#{@props.node.post_id}")
    )

    #post = _.extend(
        #{},
        #_.omit(@state.post, 'latitude', 'longitude'),
        #{
          #body: value
          #draft: false
        #}
    #)

    #if post.title is "" or post.body is ""
      #@setState errors: @state.errors.concat ["Missing title or body"]
    #else
      #@setState {
        #saving: true
        #errors: []
      #}

      #PostActions.update post

  handleDelete: ->
    #PostActions.delete(@state.post)

  handleHTTPError: (res) ->
    @setState {
      saving: false
      errors: [res.error.message]
    }

  onUpdateComplete: (res) ->
    @setState {
      unsavedChanges: false
    }

    # Since the save button was clicked, transition to the post view.
    if @state.saving
      @history.pushState(null, 'post', postId: @state.post.id)

  onDeleteComplete: ->
    @history.pushState(null, 'posts-index')

  onCreateComplete: (res) ->
    id = res.body.id
    post = _.extend @state.post, res.body

    @setState {
      unsavedChanges: false
      post: post
    }

    # Since the save button was clicked, transition to the post view.
    if @state.saving
      @history.pushState(null, 'post', postId: post.id)
