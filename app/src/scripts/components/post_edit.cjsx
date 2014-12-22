React = require 'react'
Reflux = require 'reflux'
request = require 'superagent'
marked = require('marked')
moment = require 'moment'
_ = require 'underscore'
Router = require('react-router')
MarkdownTextarea = require 'react-markdown-textarea'
ReactTextarea = require 'react-textarea-autosize'
Spinner = require 'react-spinkit'
Messages = require './messages'

PostStore = require '../stores/post_store'
LoadingStore = require '../stores/loading'
PostActions = require '../actions/PostActions'

# TODO
# validation
# saving/loading indicators
# error handling
# global error store
module.exports = React.createClass
  displayName: "PostEdit"

  mixins: [
    Reflux.connect(LoadingStore, "loading"),
    Reflux.listenTo(PostActions.updateComplete, "onUpdateComplete"),
    Reflux.listenTo(PostActions.deleteComplete, "onDeleteComplete"),
    Router.Navigation
    Router.State
  ]

  getInitialState: ->
    return {
      errors: []
    }

  componentDidMount: ->
    @getPost()

  render: ->
    unless @state.post?
      return (
        <Spinner spinnerName="wave" fadeIn cssRequire />
      )
    else
      return (
        <div className="post-edit" onClick={@handleClick}>
          <Messages type="errors" messages={@state.errors} />
          <h1>
            <ReactTextarea
              placeholder="New title for post"
              className="post-edit__title"
              rows=1
              ref="title"
              value={@state.post.title}
              onChange={@handleTitleChange} />
          </h1>
          <MarkdownTextarea
            placeholder="The body of your post"
            rows=4
            onSave={@handleSave}
            saving={@state.saving}
            deleteButton=true
            onDelete={@handleDelete}
            spinner={Spinner}
            spinnerOptions={
              fadeIn: true,
              spinnerName: "wave"
              className: "react-markdown-textarea__spinner"
            }
            initialValue={@state.post.body} />
        </div>
      )

  handleSave: (value) ->
    post = @state.post
    post.body = value

    # Validate
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

  handleTitleChange: ->
    post = _.extend @state.post, title: @refs.title.getDOMNode().value
    @setState post

  handleClick: (e) ->
    e.preventDefault()
    # Ignore unless the click was on an A element.
    if e.target.nodeName is "A"
      window.open(e.target.href, '_blank')

  getPost: ->
    PostStore.get(@getParams().postId).then (post) =>
      @setState post: post

  onUpdateComplete: ->
    @transitionTo('post', postId: @getParams().postId)

  onDeleteComplete: ->
    @transitionTo('posts-index')
