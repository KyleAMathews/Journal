React = require 'react'
Link = require('react-nested-router').Link
request = require 'superagent'

module.exports = React.createClass
  displayName: 'App'

  componentDidMount: ->
    headerEl = document.querySelector(".headroom")
    headroom  = new Headroom(headerEl, {
      tolerance: 5
      offset: 405
    })
    headroom.init()

  render: ->
    <div>
      <div className="headroom">
        <div className="headroom__links">
          <Link className="headroom__link" to="index"><span className="icon-home headroom__icon" />Home</Link>
        </div>
      </div>
      <div className="main-section">
        {@props.activeRoute}
      </div>
    </div>
