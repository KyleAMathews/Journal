Spinner = require 'react-spinkit'
Link = require('react-router').Link
Router = require('react-router')
moment = require 'moment'
_ = require 'underscore'
_str = require 'underscore.string'
request = require 'superagent'

eventBus = require '../event_bus'
AppStore = require '../stores/app_store'
SearchStore = require '../stores/search_store'
AppConstants = require '../constants/app_constants'
SearchConstants = require '../constants/search_constants'
Dispatcher = require '../dispatcher'
DateHistogram = require '../date_histogram'
Messages = require 'react-message'

module.exports = React.createClass
  displayName: "Search"

  mixins: [Router.Navigation]

  getInitialState: ->
    query = @props.query.q || ""
    sort = @props.query.sort || 'Best match'
    data = @loadFromCache(query, sort)

    return _.extend {
      loading: false
      searching: false
      lastQuery: ''
      errors: []
    }, data

  componentDidMount: ->
    # Query set and no results loaded from cache.
    if @state.query isnt "" and @state.hits.length is 0
      @search()

    # Get width of main-text area so chart is right width.
    @setState width: Math.floor(@getDOMNode().offsetWidth/25) * 25
    @createCanvas()

    @refs.query.getDOMNode().focus()

    # Change in the search store, probably means our delivery has arrived!
    SearchStore.on 'change', 'search', =>
      @search()

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
      @search(newProps.query.q, newProps.query.sort)

  # Redraw our chart when facets data change.
  componentDidUpdate: (prevProps, prevState) ->
    if prevState.facets isnt @state.facets
      @createCanvas()

  componentWillUnmount: ->
    eventBus.off()
    SearchStore.releaseGroup('search')

  render: ->
    <div className="search">
      <Messages type="errors" messages={@state.errors} />
      <select value={@state.sort} onChange={@handleSortChange}>
        <option value="">Best match</option>
        <option value="asc">Oldest first</option>
        <option value="desc">Newest first</option>
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
      {if @state.searching then <Spinner spinnerName="wave" cssRequire />}
      {@meta()}
      {if @state.facets.length > 1
        <div
          key={"#{@state.lastQuery}-#{@state.sort}"}
          className="search__histogram" />
      }
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
    unless @state.hits.length > 0 then return
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
            <Link to="post" params={{postId: result._source.nid}}>
              <span className="search__result__title" dangerouslySetInnerHTML={__html:title} />
            </Link>
            <span className="search__result__date"> — {moment(result._source.created).format("D MMMM YYYY")}</span>
          </h3>
        <p dangerouslySetInnerHTML={__html:body} />
      </div>

  handleSortChange: (e) ->
    @setState sort: e.target.value, ->
      @search()

  handleKeyUp: (e) ->
    if e.key is "Enter"
      @search()

  # Text in inbox changed.
  handleChange: (e) ->
    e.preventDefault()
    @setState query: @refs.query.getDOMNode().value

  # User clicked on search button.
  handleClick: (e) ->
    @search()

  loadFromCache: (query=@state.lastQuery, sort=@state.sort) ->
    if query isnt "" and sort
      data = SearchStore.get(query, sort)
    unless data?
      data = {
        lastQuery: query
        query: query
        sort: sort
        hits: []
        facets: []
        total: 0
        took: undefined
      }
      if query isnt ""
        data.searching = true
    else if data.error
      @setState
        errors: [data.message]
        searching: false
    else
      data = _.extend data, {
        lastQuery: query
        searching: false
      }

    return data

  search: (query=@state.query, sort=@state.sort) ->
    # Set to the URL our search query strings.
    @transitionTo('search', null, {
      q: query
      sort: sort
    })

    @setState @loadFromCache(query, sort)

  searchMore: ->
    request
      .get('/search')
      .set('Accept', 'application/json')
      .query(q: @state.query)
      .query(size: @state.size)
      .query(start: @state.hits.length)
      .query(sort: @state.sort)
      .end (err, res) =>
        @setState {
          hits: @state.hits.concat res.body.hits.hits
          loading: false
        }

  createCanvas: ->
    if @state.facets.length > 1
      DateHistogram(
        values: (@state.facets.map (facet) -> facet.time)
        selector: ".search__histogram"
        containerWidth: @state.width
      )
