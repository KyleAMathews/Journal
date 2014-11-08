React = require 'react/addons'
moment = require 'moment'
_ = require 'underscore'
Link = require('react-router').Link
Spinner = require 'react-spinkit'
Reflux = require 'reflux'

PostListItem = require './post_list_item'
postStore = require '../stores/post_store'
loadingStore = require '../stores/loading'
PostActions = require '../actions/PostActions'

module.exports = React.createClass
  displayName: 'PostsIndex'

  mixins: [Reflux.connect(postStore, "posts"), Reflux.connect(loadingStore, "loading")]

  componentDidMount: ->
    window.addEventListener('scroll', @distanceToBottom)
    @listenTo PostActions.loadMoreComplete, -> @setState loading: false

  componentWillUnmount: ->
    window.removeEventListener('scroll', @distanceToBottom)

  render: ->
    months = {}
    posts = []
    if @state?.posts?
      @state.posts.forEach (post) ->
        if post.deleted then return
        month = moment(post.created_at).format('MMMM YYYY')
        unless months[month]?
          posts.push <h2 className="posts-index__month" key={month}>{month}</h2>
          months[month] = true
        posts.push <PostListItem key={post.id} post={post}></PostListItem>

      return (
        <div className="posts-index">
          <Link
           className="button posts-index__new-post"
           to="new-post">
             <span className="icon-flat-pencil" />New post
          </Link>
          <ul className="posts-index__list">
            {posts}
          </ul>
        </div>
      )

    else
      return (
        <Spinner spinnerName="wave" fadeIn cssRequire />
      )

  distanceToBottom: ->
    w = window
    d = document
    e = d.documentElement
    g = d.getElementsByTagName('body')[0]
    x = w.innerWidth || e.clientWidth || g.clientWidth
    y = w.innerHeight|| e.clientHeight|| g.clientHeight

    distanceToBottom = document.body.clientHeight - window.scrollY - y

    if distanceToBottom < 300 and @state.posts? and not @state.loading
      PostActions.loadMore(@state.posts.last())
