React = require 'react'
Reflux = require 'reflux'
Router = require('react-router')

PostStore = require '../stores/post_store'
LoadingStore = require '../stores/loading'
PostActions = require '../actions/PostActions'
SaveMixin = require '../mixins/save'

module.exports = React.createClass
  displayName: "PostEdit"

  mixins: [
    Reflux.connect(LoadingStore, "loading"),
    Router.Navigation
    Router.State
    SaveMixin
  ]

  componentDidMount: ->
    PostStore.get(@getParams().postId).then (post) =>
      @setState post: post
