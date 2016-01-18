import React from 'react'
import {Router, Link } from 'react-router'
import Relay from 'react-relay'
import moment from 'moment'
import Spinner from 'react-spinkit'
import _str from 'underscore.string'
import Messages from 'react-message'
import marked from 'marked'
import prettyMs from 'pretty-ms'
import gray from 'gray-percentage'
import access from 'safe-access'

import { typography } from '../typography'
const rhythm = typography.rhythm
//DateHistogram = require '../date_histogram'

const Search = React.createClass({
  mixins: [Router.Navigation],
  displayName: 'Search',

  getInitialState() {
    return {
      errors: [],
      query: ''
    }
  },

  componentDidMount() {
    this.refs.query.focus()
  },

  render() {
    const {input, button} = require('react-simple-form-inline-styles')(rhythm);

    console.log(this.props)
    let loadMore
    if (access(this, 'props.viewer.search.pageInfo.hasNextPage')) {
      loadMore = (
        <button
          onClick={this.searchMore}
        >
          Load more
        </button>
      )
    }

    return (
      <div className="search">
        <Messages type="error" messages={this.state.errors} />
        <select value={this.props.sort} onChange={this.handleSortChange}>
          <option value="">Best match</option>
          <option value="asc">Oldest first</option>
          <option value="desc">Newest first</option>
        </select>
        <br />
        <br />
        <input
          style={input}
          ref="query"
          value={this.props.query}
          onChange={this.handleChange}
          onKeyUp={this.handleKeyUp} />
        <button
          style={button}
          onClick={this.handleClick}
        >
          Search
        </button>
        {this.meta()}
        <div>{this.results()}</div>
        {loadMore}
      </div>
    )
  },

  meta() {
    if(this.props.viewer.search && this.props.viewer.search.took) {
      return (
        <div
          style={{
            marginBottom: rhythm(1)
          }}
        >
          <small
            style={{
              color: gray(60, 'warm')
            }}
          >
            {this.props.viewer.search.total} results in {prettyMs(this.props.viewer.search.took)}
          </small>
        </div>
      )
    }
  },

  results() {
    if (!this.props.viewer.search) return;
    return this.props.viewer.search.edges.map(function(edge) {
      const post = edge.node
      const title = post.title;
      const body = _str.prune(post.body, 200);
      return (
        <div key={post.post_id} className="search__result">
          <h5
            style={{
              marginBottom: 0
            }}
          >
            <Link
              to={`/posts/${post.post_id}`}
              style={{
                textDecoration: 'none'
              }}
            >
            <span
              className="search__result__title"
              dangerouslySetInnerHTML={{__html:title}}
            />
            </Link>
            <span
              style={{
                color: gray(50, 'warm')
              }}
            >
              {' '}— {moment(post.created_at).format('D MMMM YYYY')}</span>
          </h5>
          <p
            dangerouslySetInnerHTML={{__html: body}}
          />
        </div>
      )
    })
  },

  handleSortChange(e) {
    this.search(this.state.query, e.target.value)
  },

  handleKeyUp(e) {
    if (e.key === 'Enter') {
      this.search()
    }
  },

  // Text in inbox changed.
  handleChange(e) {
    e.preventDefault()
    this.setState({
      query: e.target.value
    })
  },

  // User clicked on search button.
  handleClick(e) {
    this.search()
  },

  search() {
    this.props.relay.setVariables({
      query: this.state.query
    })

    // Update url
    //this.transitionTo('search', null, {
      //q: this.state.query,
      //sort: this.state.sort
    //})
  },

  searchMore() {
    // Increment variables.
    this.props.relay.setVariables({
      first: this.props.relay.variables.first + 20
    })
  },

  //createCanvas: ->
    //if @state.facets.length > 1
      //DateHistogram(
        //values: (@state.facets.map (facet) -> facet.time)
        //selector: ".search__histogram"
        //containerWidth: @state.width
      //)
});

export default Relay.createContainer(Search, {
  // TODO Use directives + set variables to false to not do search when
  // first loading page.
  initialVariables: {
    first: 20,
    query: null,
    sort: null
  },

  fragments: {
    viewer: () =>
      Relay.QL`
        fragment on User {
          name
          search(first: $first, query: $query) {
            took
            total
            pageInfo {
              hasNextPage
            }
            edges {
              node {
                id
                post_id
                title
                body
                created_at
              }
            }
          }
        }
      `
  }
});
