React = require 'react'
request = require 'superagent'
marked = require('marked')
moment = require 'moment'

postsDAO = require '../posts'

module.exports = React.createClass
  getInitialState: ->
    return {
      title: ''
      body: ''
    }

  componentDidMount: ->
    postsDAO.getPost @props.params.postId, (post) =>
      @setState post

  render: ->
    <div>
      <h1>{@state.title}</h1>
      <small>{moment(@state.created_at).format('dddd, MMMM Do YYYY, h:mma')}</small>
      <div dangerouslySetInnerHTML={__html:marked(@state.body, smartypants:true)}></div>
    </div>
