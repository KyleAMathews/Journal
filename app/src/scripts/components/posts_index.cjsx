React = require 'react/addons'
moment = require 'moment'
_ = require 'underscore'
Link = require('react-router').Link
Spinner = require 'react-spinkit'
Reflux = require 'reflux'

PostListItem = require './post_list_item'
postStore = require '../stores/post_store'

module.exports = React.createClass
  displayName: 'PostsIndex'

  mixins: [Reflux.connect(postStore, "posts")]

  getInitialState: ->
    return {
      start: new Date().toJSON()
      loading: false
    }

  render: ->
    months = {}
    posts = []
    if @state.posts?
      for post in @state.posts
        if post.deleted then continue
        month = moment(post.created_at).format('MMMM YYYY')
        unless months[month]?
          posts.push <h2 className="posts-index__month" key={month}>{month}</h2>
          months[month] = true
        posts.push <PostListItem key={post.id} post={post}></PostListItem>

      return (
        <div className="posts-index">
          <Link className="button posts-index__new-post" to="new-post"><span className="icon-flat-pencil" />New post</Link>
          <ul className="posts-index__list">
            {posts}
          </ul>
        </div>
      )

    else
      return (
        <Spinner spinnerName="wave" fadeIn cssRequire />
      )
