React = require 'react/addons'
moment = require 'moment'
_ = require 'underscore'
Link = require('react-router').Link
Spinner = require 'react-spinkit'
Reflux = require 'reflux'

PostListItem = require './post_list_item'
draftsStore = require '../stores/drafts_store'
loadingStore = require '../stores/loading'
PostActions = require '../actions/PostActions'

module.exports = React.createClass
  displayName: 'PostsIndex'

  mixins: [
    Reflux.connect(draftsStore, "posts"),
    Reflux.connect(loadingStore, "loading")
  ]

  render: ->
    console.log @state
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
          <h1>Drafts</h1>
          <ul className="posts-index__list">
            {posts}
          </ul>
        </div>
      )
    else
      <div/>
