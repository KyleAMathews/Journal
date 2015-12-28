React = require 'react'
_ = require 'underscore'
{typography} = require '../typography'
{rhythm} = typography

module.exports = React.createClass

  render: ->
    {button} = require('react-simple-form-inline-styles')(rhythm)

    <button
      style={
        _.extend(button, {
          padding: "#{rhythm(1/3)} #{rhythm(2/3)}"
        })
      }
      {...@props}
    >
     {@props.children}
    </button>

