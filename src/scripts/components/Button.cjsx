React = require 'react/addons'
_ = require 'underscore'

module.exports = React.createClass

  render: ->
    {button} = require('react-simple-form-inline-styles')(@props.rhythm)

    <button
      style={
        _.extend(button, {
          padding: "#{@props.rhythm(1/3)} #{@props.rhythm(2/3)}"
        })
      }
    >
     {@props.children}
    </button>

