uuid = require('node-uuid')
Router = require('react-router')
_ = require 'underscore'
Reflux = require 'reflux'

SaveMixin = require '../mixins/save'

module.exports = React.createClass
  displayName: 'NewPost'

  mixins: [
    Router.Navigation
    Router.State
    SaveMixin
  ]

  getInitialState: ->
    return {
      post:
        title: ''
        body: ''
        created_at: new Date().toJSON()
        deleted: false
        starred: false
    }

  componentDidMount: ->
    React.findDOMNode(@refs.title).focus()
