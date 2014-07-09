Spinner = require 'react-spinner'
Link = require('react-nested-router').Link
Router = require('react-nested-router')
moment = require 'moment'
_ = require 'underscore'
_str = require 'underscore.string'
request = require 'superagent'

eventBus = require '../event_bus'

module.exports = React.createClass
  displayName: "Search"
  getInitialState: ->
    {
      query: @props.query.q || ""
      hits: []
      facets: []
      total: 0
      size: 30
      offset: 0
      loading: false
      searching: false
    }

  componentDidMount: ->
    if @state.query isnt ""
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

  componentWillUnmount: ->
    eventBus.off()

  render: ->
    <div className="search">
      <input
        className="search__input"
        ref="query"
        value={@state.query}
        onChange={@handleChange}
        onKeyDown={@handleKeyDown} />
      <button className="search__button" onClick={@handleClick}>Search</button>
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
      if result.highlight.title?
        title = result.highlight.title[0]
      else
        title = result._source.title
      if result.highlight.body?
        body = result.highlight.body[0]
      else
        body = _str.prune(result._source.body, 200)
      <div className="search__result">
          <h3>
            <Link to="post" postId={result._source.nid}>
              <span className="search__result__title" dangerouslySetInnerHTML={__html:title} />
            </Link>
            <span className="search__result__date"> — {moment(result._source.created).format("D MMMM YYYY")}</span>
          </h3>
        <p dangerouslySetInnerHTML={__html:body} />
      </div>

  handleKeyDown: (e) ->
    if e.key is "Enter"
      @search()

  handleChange: (e) ->
    e.preventDefault()
    @setState query: @refs.query.getDOMNode().value

  handleClick: (e) ->
    @search()

  search: ->
    @setState searching: true
    Router.transitionTo('search', null, {q: @state.query})
    searchStart = new Date()
    request
      .get('/search')
      .set('Accept', 'application/json')
      .query(q: @state.query)
      .query(size: @state.size)
      .end (err, res) =>
        console.log res
        @setState {
          hits: res.body.hits.hits
          facets: res.body.facets.month.entries
          total: res.body.hits.total
          took: new Date() - searchStart
          searching: false
        }

  searchMore: ->
    request
      .get('/search')
      .set('Accept', 'application/json')
      .query(q: @state.query)
      .query(size: @state.size)
      .query(start: @state.hits.length)
      .end (err, res) =>
        @setState {
          hits: @state.hits.concat res.body.hits.hits
          loading: false
        }
