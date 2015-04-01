Reflux = require 'reflux'

SearchStore = require '../stores/SearchStore'
Search = require './search'

module.exports = React.createClass
  displayName: "SearchController"

  mixins: [Reflux.connect(SearchStore, 'search')]

  render: ->
    <Search search={@state.search} {...@props} />

