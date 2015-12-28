import React, { Component } from 'react'
import { Link } from 'react-router'
import Headroom from 'react-headroom'
import gray from 'gray-percentage'
import {Container} from 'react-responsive-grid'
import { typography } from '../typography'
const rhythm = typography.rhythm
import Relay from 'react-relay'

class App extends Component {
  static displayName = 'App'

  render() {
    const headerLinkStyles = {
      color: gray(90),
      marginRight: rhythm(1),
      textDecoration: 'none'
    }

    return (
      <div>
        <Headroom
          style={{
            background: gray(20, 'warm'),
            color: gray(90),
            fontFamily: typography.options.headerFontFamily
          }}
        >
          <Container
            style={{
              maxWidth: 600,
              padding: rhythm(1/2),
              paddingLeft: rhythm(3/4)
            }}
          >
            <Link
              style={headerLinkStyles}
              to="/"
            >
              Home
            </Link>
            <Link
              style={headerLinkStyles}
              to="/search"
            >
              Search
            </Link>
            <Link
              style={headerLinkStyles}
              to="/drafts"
            >
              Drafts
            </Link>
          </Container>
        </Headroom>
        <Container
          style={{
            maxWidth: 600,
            padding: rhythm(1),
            paddingTop: rhythm(1.75)
          }}
        >
          {this.props.children}
        </Container>
      </div>
    )
  }
}

export default Relay.createContainer(App, {
  fragments: {
    viewer: () => Relay.QL`
      fragment on User {
        name
      }
    `
  }
});
