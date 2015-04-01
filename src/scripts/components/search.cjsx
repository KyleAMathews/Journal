Spinner = require 'react-spinkit'
Link = require('react-router').Link
Router = require('react-router')
moment = require 'moment'
_ = require 'underscore'
_str = require 'underscore.string'
request = require 'superagent'
prettyMs = require 'pretty-ms'
Messages = require 'react-message'
gray = require 'gray-percentage'

DateHistogram = require '../date_histogram'
SearchActions = require '../actions/SearchActions'

module.exports = React.createClass
  displayName: "Search"

  mixins: [Router.Navigation]

  # TODO
  # Perform actual searches with actions
  # restore searchMore (as action)
  # Set query etc. when changing the search
  # restore getInitialState's ability to do search automatically

  getInitialState: ->
    {
      sort: ''
      errors: []
      hits: []
    }
    #query = @props.query.q || ""
    #sort = @props.query.sort || 'Best match'
    #data = @loadFromCache(query, sort)

    #return _.extend {
      #loading: false
      #searching: false
      #lastQuery: ''
      #errors: []
    #}, data

  componentDidMount: ->
    ## Query set and no results loaded from cache.
    #if @state.query isnt "" and @state.hits.length is 0
      #@search()

    ## Get width of main-text area so chart is right width.
    #@setState width: Math.floor(@getDOMNode().offsetWidth/25) * 25
    #@createCanvas()

    @refs.query.getDOMNode().focus()

    ## Change in the search store, probably means our delivery has arrived!
    #SearchStore.on 'change', 'search', =>
      #@search()

    ## Listen for when getting close to the bottom
    ## so we can load more.
    #throttled = _.throttle ((distance) =>
      #if distance < 2000 and not
        #@state.loading and not
        #(@state.total is @state.hits.length)
          #@setState loading: true
          #@searchMore()
    #), 250

    #eventBus.on 'scrollBottom', throttled

  # URL changed so we need to update our internal state.
  #componentWillReceiveProps: (newProps) ->
    #if newProps.query.q isnt @state.query or newProps.query.sort isnt @state.sort
      #@search(newProps.query.q, newProps.query.sort)

  ## Redraw our chart when facets data change.
  #componentDidUpdate: (prevProps, prevState) ->
    #if prevState.facets isnt @state.facets
      #@createCanvas()

  #componentWillUnmount: ->
    #eventBus.off()
    #SearchStore.releaseGroup('search')

  render: ->
    {input, button} = require('react-simple-form-inline-styles')(@props.rhythm)

    <div className="search">
      <Messages type="error" messages={@state.errors} />
      <select value={@props.search.sort} onChange={@handleSortChange}>
        <option value="">Best match</option>
        <option value="asc">Oldest first</option>
        <option value="desc">Newest first</option>
      </select>
      <br />
      <br />
      <input
        style={input}
        ref="query"
        value={@props.search.query}
        onChange={@handleChange}
        onKeyUp={@handleKeyUp} />
      <button
        style={button}
        onClick={@handleClick}
      >
        Search
      </button>
      {if @state.searching then <Spinner spinnerName="wave" cssRequire />}
      {@meta()}
      {if false #if @state.facets.length > 1
        <div
          key={"#{@state.lastQuery}-#{@props.search.sort}"}
          className="search__histogram" />
      }
      {@results()}
    </div>

  meta: ->
    if @props.search.took
      <div
        style={{
          marginBottom: @props.rhythm(1)
        }}
      >
        <small
          style={{
            color: gray(60, 'warm')
          }}
        >
          {@props.search.total} results in {prettyMs(@props.search.took)}
        </small>
      </div>

  results: ->
    unless @props.search.hits.length > 0 then return
    results = @props.search.hits.map (result) =>
      title = result.title
      body = _str.prune(result.body, 200)
      <div key={result.id} className="search__result">
          <h5
            style={{
              marginBottom: 0
            }}
          >
            <Link
              to="post"
              params={{postId: result.id}}
              style={{
                textDecoration: 'none'
              }}
            >
              <span className="search__result__title" dangerouslySetInnerHTML={__html:title} />
            </Link>
            <span
              style={{
                color: gray(50, 'warm')
              }}
            >
              {' '}— {moment(result.created_at).format("D MMMM YYYY")}</span>
          </h5>
        <p dangerouslySetInnerHTML={__html:body} />
      </div>

  handleSortChange: (e) ->
    @search(@props.search.query, e.target.value)

  handleKeyUp: (e) ->
    if e.key is "Enter"
      @search()

  # Text in inbox changed.
  handleChange: (e) ->
    e.preventDefault()
    SearchActions.updateQuery(e.target.value)

  # User clicked on search button.
  handleClick: (e) ->
    @search()

  search: (query=@props.search.query, sort=@props.search.sort) ->
    SearchActions.search(query, sort)
    # Set to the URL our search query strings.
    #@transitionTo('search', null, {
      #q: query
      #sort: sort
    #})

    #@setState @loadFromCache(query, sort)
    #

  searchMore: ->
    request
      .get('localhost:8081/search')
      .set('Accept', 'application/json')
      .query(q: @props.search.query)
      .query(size: @state.size)
      .query(start: @state.hits.length)
      .query(sort: @props.search.sort)
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
