React = require 'react'
request = require 'superagent'
marked = require('marked')
moment = require 'moment'
Router = require('react-nested-router')

postsDAO = require '../posts'

module.exports = React.createClass
  getInitialState: ->
    return {
      title: ''
      body: ''
    }

  componentDidMount: ->
    # Ensure we're at the top of the page.
    scroll(0,0)

    # Fetch the post data.
    postsDAO.getPost @props.params.postId, (post) =>
      @setState post

  # Handle clicks on interlinks between posts.
  handleClick: (e) ->
    e.preventDefault()
    path = e.target.pathname?.split('/')
    if path[1] is "posts" and path[2]?
      Router.transitionTo('post', postId: path[2])

  render: ->
    <div>
      <h1>{@state.title}</h1>
      <small>{moment(@state.created_at).format('dddd, MMMM Do YYYY, h:mma')}</small>
      <div onClick={@handleClick} dangerouslySetInnerHTML={__html:marked(@state.body, smartypants:true)}></div>
    </div>
