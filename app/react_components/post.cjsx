React = require 'react'
request = require 'superagent'
marked = require('marked')

module.exports = React.createClass
  getInitialState: ->
    return {
      title: ''
      body: ''
    }

  componentDidMount: ->
    request
      .get("/posts/#{@props.params.postId}")
      .set('Accept', 'application/json')
      .end (err, res) =>
        @setState res.body

  render: ->
    <div>
      <h1>{@state.title}</h1>
      <small>{moment(@state.created_at).format('dddd, MMMM Do YYYY, h:mma')}</small>
      <div dangerouslySetInnerHTML={__html:marked(@state.body, smartypants:true)}></div>
    </div>
