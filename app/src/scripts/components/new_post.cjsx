uuid = require('node-uuid')
Router = require('react-router')
_ = require 'underscore'

AppStore = require '../stores/app_store'
PostActions = require '../actions/PostActions'
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
        latitude: AppStore.get('coordinates')?.latitude
        longitude: AppStore.get('coordinates')?.longitude
        deleted: false
        starred: false
    }

  componentDidMount: ->
    @refs.title.getDOMNode().focus()
