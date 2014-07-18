React = require 'react/addons'
request = require 'superagent'
moment = require 'moment'
_ = require 'underscore'
Link = require('react-nested-router').Link
Spinner = require 'react-spinner'

SetInterval = require '../mixins/set_interval'
PostListItem = require './post_list_item'
eventBus = require '../event_bus'
PostStore = require '../stores/post_store'
Dispatcher = require '../dispatcher'
AppConstants = require '../constants/app_constants'

module.exports = React.createClass
  displayName: 'PostsIndex'
  getInitialState: ->
    return {
      posts: PostStore.getAll()
      start: new Date().toJSON()
      loading: false
    }

  componentDidMount: ->
    throttled = _.throttle ((distance) =>
      if distance < 2000 and not @state.loading
        @setState loading: true
        Dispatcher.emit('POSTS_FETCH')
    ), 250

    eventBus.on 'scrollBottom', throttled
    PostStore.on('change', =>
      @setState {
        posts: PostStore.getAll()
        loading: false
      }
    )

  componentWillUnmount: ->
    eventBus.off()
    PostStore.off('change')

  render: ->
    console.time('sort-index-posts')
    months = {}
    posts = []
    for post in @state.posts
      if post.deleted then continue
      month = moment(post.created_at).format('MMMM YYYY')
      unless months[month]?
        posts.push <h2 className="posts-index__month" key={month}>{month}</h2>
        months[month] = true
      posts.push <PostListItem key={post.id} post={post}></PostListItem>
    console.timeEnd('sort-index-posts')

    if _.isEmpty(PostStore.getAll())
      return (
        <Spinner />
      )
    else
      return (
        <div className="posts-index">
          <Link className="button posts-index__new-post" to="new-post"><span className="icon-flat-pencil" />New post</Link>
          <ul className="posts-index__list">
            {posts}
          </ul>
        </div>
      )
