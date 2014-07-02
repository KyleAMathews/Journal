React = require 'react'
Link = require('react-nested-router').Link
request = require 'superagent'
moment = require 'moment'
_ = require 'underscore'

SetInterval = require '../mixins/set_interval'
eventBus = require '../event_bus'
postsDAO = require '../posts'

module.exports = React.createClass
  displayName: 'Index'
  getInitialState: ->
    return {
      posts: []
      start: new Date().toJSON()
      loading: false
    }

  nextPage: ->
    @setState loading: true
    postsDAO.nextPage offset: @state.posts.length, (newPosts) =>
      @setState {
        posts: @state.posts.concat newPosts
        loading: false
      }

  componentDidMount: ->
    @nextPage()
    throttled = _.throttle ((distance) =>
      if distance < 2000 and not @state.loading
        @nextPage()
    ), 250

    eventBus.on 'scrollBottom', throttled

  componentWillUnmount: ->
    eventBus.off()

  render: ->
    months = {}
    posts = []
    for post in @state.posts
      month = moment(post.get('created_at')).format('MMMM YYYY')
      unless months[month]?
        posts.push <h2 className="posts-index__month" key={month}>{month}</h2>
        months[month] = true
      posts.push <li key={post.id}><Link to="post" postId={post.id}>{post.get('title')}</Link></li>

    return (
      <div className="posts-index">
        <ul className="posts-index__list">
          {posts}
        </ul>
      </div>
    )
