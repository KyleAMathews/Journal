React = require 'react'
Link = require('react-router').Link
RouteHandler = require('react-router').RouteHandler
request = require 'superagent'
#window.jQuery = window.$ = require 'jquery'
#require 'velocity-animate'

module.exports = React.createClass
  displayName: 'App'

  handleClickHome: ->
    #if document.location.pathname is "/"
      #$('body').velocity("scroll", { duration: 1000, offset: -85 })

  render: ->
    <div>
      <div className="headroom">
        <div onClick={@handleClickHome} className="headroom__links">
          <Link className="headroom__link" to="posts-index">
            <span className="icon-home headroom__icon" />Home
          </Link>
          <Link className="headroom__link" to="search">
            <span className="icon-search headroom__icon" />Search
          </Link>
        </div>
      </div>
      <div className="main-section">
        <RouteHandler/>
      </div>
    </div>
