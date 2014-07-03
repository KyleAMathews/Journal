React = require 'react'
request = require 'superagent'
marked = require('marked')
moment = require 'moment'
Router = require('react-nested-router')
MarkdownTextarea = require 'react-markdown-textarea'
ReactTextarea = require 'react-textarea-autosize'
Spinner = require 'react-spinner'
_ = require 'underscore'

postsDAO = require '../posts'

module.exports = React.createClass
  getInitialState: ->
    return {
      title: ''
      body: ''
      loading: true
    }

  componentWillMount: ->
    # Ensure we're at the top of the page.
    scroll(0,0)

    # Fetch the post data.
    postsDAO.getPost @props.params.postId, (post) =>
      post = _.extend post, loading: false
      @setState post

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
          <h1><ReactTextarea rows=1 className="post-edit__title" ref="title" autosize value={@state.title} onChange={@handleTitleChange} /></h1>
          <MarkdownTextarea rows=1 initialValue={@state.body} />
        </div>
      )

  handleTitleChange: ->
    @setState title: @refs.title.getDOMNode().value

  handleClick: (e) ->
    e.preventDefault()
    # Ignore unless the click was on an A element.
    if e.target.nodeName is "A"
      console.log _.extend {}, e
      window.open(e.target.href, '_blank')

