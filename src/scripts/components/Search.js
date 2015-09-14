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

  //componentDidMount() {
    //## Query set and no results loaded from cache.
    //#if @state.query isnt "" and @state.hits.length is 0
      //#@search()

    //## Get width of main-text area so chart is right width.
    //#@setState width: Math.floor(@getDOMNode().offsetWidth/25) * 25
    //#@createCanvas()

    //@refs.query.getDOMNode().focus()

    //## Change in the search store, probably means our delivery has arrived!
    //#SearchStore.on 'change', 'search', =>
      //#@search()

  //# URL changed so we need to update our internal state.
  //#componentWillReceiveProps: (newProps) ->
    //#if newProps.query.q isnt @state.query or newProps.query.sort isnt @state.sort
      //#@search(newProps.query.q, newProps.query.sort)

  //## Redraw our chart when facets data change.
  //#componentDidUpdate: (prevProps, prevState) ->
    //#if prevState.facets isnt @state.facets
      //#@createCanvas()

  //#componentWillUnmount: ->
    //#eventBus.off()
    //#SearchStore.releaseGroup('search')

  render() {
    const {input, button} = require('react-simple-form-inline-styles')(rhythm);
    //if (this.props.viewer.search && this.props.viewer.search.pageInfo.hasNextPage) {
      //const loadMore = <button>Load more</button;
    //}

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
        <button
          onClick={this.searchMore}
        >
          Load more
        </button>
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
