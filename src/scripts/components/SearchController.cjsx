React = require 'react'

module.exports = React.createClass
  displayName: "SearchController"

  render: ->
    <Search search={@state.search} {...@props} />

