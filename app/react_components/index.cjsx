React = require 'react'
Link = require('react-nested-router').Link
request = require 'superagent'
SetInterval = require '../mixins/set_interval'

module.exports = React.createClass
  displayName: 'Index'
  getInitialState: ->
    return {
      posts: []
      start: 9999999
    }

  fetchPosts: ->
    request
      .get('/posts')
      .query('start': @state.start, limit: 40)
      .set('Accept', 'application/json')
      .end (err, res) =>
        @setState posts: @state.posts.concat res.body
        @setState start: res.body.pop().id - 1

  componentDidMount: ->
    @fetchPosts()

  render: ->
    posts = @state.posts.map (post) ->
      <li key={post.id}><Link to="post" postId={post.id}>{post.title}</Link></li>
    return (
      <div>
        <h1>All the posts</h1>
        <ul>
          {posts}
        </ul>
      </div>
    )
