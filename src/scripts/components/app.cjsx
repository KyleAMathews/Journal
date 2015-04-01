React = require 'react'
Link = require('react-router').Link
RouteHandler = require('react-router').RouteHandler
Headroom = require 'react-headroom'
gray = require 'gray-percentage'
{Container} = require 'react-responsive-grid'

module.exports = React.createClass
  displayName: 'App'

  render: ->
    headerLinkStyles =
      color: gray(90)
      marginRight: @props.rhythm(1)
      textDecoration: 'none'

    <div>
      <Headroom
        style={{
          background: gray(20, 'warm')
          fontFamily: @props.typography.options.headerFontFamily
        }}
      >
        <Container
          style={{
            maxWidth: 600
            padding: @props.rhythm(1/2)
            paddingLeft: @props.rhythm(3/4)
          }}
        >
          <Link
            style={headerLinkStyles}
            to="posts-index"
          >
            Home
          </Link>
          <Link
            style={headerLinkStyles}
            to="search"
          >
            Search
          </Link>
          <Link
            style={headerLinkStyles}
            to="drafts-index"
          >
            Drafts
          </Link>
        </Container>
      </Headroom>
      <Container
        style={{
          maxWidth: 600
          padding: @props.rhythm(1)
          paddingTop: @props.rhythm(1.75)
        }}
      >
        <RouteHandler {...@props}/>
      </Container>
    </div>
