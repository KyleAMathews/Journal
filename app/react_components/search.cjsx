Spinner = require 'react-spinner'
Link = require('react-nested-router').Link
Router = require('react-nested-router')
moment = require 'moment'
_ = require 'underscore'
_str = require 'underscore.string'
request = require 'superagent'

eventBus = require '../event_bus'
AppStore = require '../stores/app_store'
AppConstants = require '../constants/app_constants'
Dispatcher = require '../dispatcher'

module.exports = React.createClass
  displayName: "Search"

  getInitialState: ->
    query = @props.query.q || ""
    sort = @props.query.sort || 'Best match'
    data = @loadFromCache(query, sort)

    return _.extend {
      loading: false
      searching: false
      size: 30
    }, data

  componentDidMount: ->
    # Query set and no results loaded from cache.
    if @state.query isnt "" and @state.hits.length is 0
      @search()

    @refs.query.getDOMNode().focus()

    # Listen for when getting close to the bottom
    # so we can load more.
    throttled = _.throttle ((distance) =>
      if distance < 2000 and not
        @state.loading and not
        (@state.total is @state.hits.length)
          @setState loading: true
          @searchMore()
    ), 250

    eventBus.on 'scrollBottom', throttled

  # URL changed so we need to update our internal state.
  componentWillReceiveProps: (newProps) ->
    if newProps.query.q isnt @state.query or newProps.query.sort isnt @state.sort
      # Don't need to search or transition because since we're moving
      # to a know history item, there will be cached results and we
      # don't need to transition (again).
      @setState @loadFromCache(newProps.query.q, newProps.query.sort)

  componentWillUnmount: ->
    eventBus.off()

  render: ->
    <div className="search">
      <small>Sort: </small>
      <select value={@state.sort} onChange={@handleSortChange}>
        <option>Best match</option>
        <option>Oldest first</option>
        <option>Newest first</option>
      </select>
      <br />
      <br />
      <input
        className="search__input"
        ref="query"
        value={@state.query}
        onChange={@handleChange}
        onKeyUp={@handleKeyUp} />
      <button className="search__button" onClick={@handleClick}>
        <span className="icon-search" />
        Search
      </button>
      {if @state.searching then <Spinner className="search__spinner" />}
      {@meta()}
      {@results()}
    </div>

  meta: ->
    if @state.took
      <div>
        <small className="search__meta">
          {@state.total} results ({@state.took/1000} seconds)
        </small>
      </div>

  results: ->
    results = @state.hits.map (result) ->
      # If there's a highlighted version, default to that.
      if result.highlight.title?
        title = result.highlight.title[0]
      else
        title = result._source.title
      if result.highlight.body?
        body = result.highlight.body[0]
      else
        body = _str.prune(result._source.body, 200)
      <div key={result._source.nid} className="search__result">
          <h3>
            <Link to="post" postId={result._source.nid}>
              <span className="search__result__title" dangerouslySetInnerHTML={__html:title} />
            </Link>
            <span className="search__result__date"> — {moment(result._source.created).format("D MMMM YYYY")}</span>
          </h3>
        <p dangerouslySetInnerHTML={__html:body} />
      </div>

  handleSortChange: (e) ->
    @resetState(@state.query, e.target.value)

  handleKeyUp: (e) ->
    if e.key is "Enter"
      @resetState(@state.query, @state.sort)

  # Text in inbox changed.
  handleChange: (e) ->
    e.preventDefault()
    @setState query: @refs.query.getDOMNode().value

  # User clicked on search button.
  handleClick: (e) ->
    @resetState(@state.query, e.target.value)

  transitionTo: ->
    Router.transitionTo('search', null, {
      q: @state.query
      sort: @state.sort
    })

  search: ->
    @transitionTo()

    @setState
      searching: true

    searchStart = new Date()
    request
      .get('/search')
      .set('Accept', 'application/json')
      .query(q: @state.query)
      .query(size: @state.size)
      .query(sort: @sortStyle())
      .end (err, res) =>
        @setState {
          hits: res.body.hits.hits
          facets: res.body.facets.month.entries
          total: res.body.hits.total
          took: new Date() - searchStart
          searching: false
        }, ->
          # Cache result.
          Dispatcher.emit(
            AppConstants.SEARCH_CACHE,
            @searchSerializeKey(@state.query, @state.sort),
            {
              query: @state.query
              sort: @state.sort
              hits: @state.hits
              facets: @state.facets
              total: @state.total
              took: @state.took
              sort: @state.sort
            }
          )

  searchMore: ->
    request
      .get('/search')
      .set('Accept', 'application/json')
      .query(q: @state.query)
      .query(size: @state.size)
      .query(start: @state.hits.length)
      .query(sort: @sortStyle())
      .end (err, res) =>
        @setState {
          hits: @state.hits.concat res.body.hits.hits
          loading: false
        }

  sortStyle: ->
    sortStyle = ""
    switch @state.sort
      when "Best match"
        sortStyle = ''
      when "Oldest first"
        sortStyle = "asc"
      when "Newest first"
        sortStyle = "desc"

    return sortStyle

  resetState: (query, sort) ->
    @setState @loadFromCache(query, sort), ->
      # Cache miss
      if @state.hits.length is 0
        @search()
      # Cache hit
      else
        @transitionTo()

  loadFromCache: (query, sort) ->
    data = AppStore.get(@searchSerializeKey(query, sort))
    unless data?
      data = {
        query: query
        sort: sort
        hits: []
        facets: []
        total: 0
        took: undefined
      }

    return data

  searchSerializeKey: (query, sort) ->
    "search-#{query}-#{sort}"
