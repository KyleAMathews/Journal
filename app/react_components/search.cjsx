Spinner = require 'react-spinner'
Link = require('react-nested-router').Link
Router = require('react-nested-router')
moment = require 'moment'
_ = require 'underscore'
_str = require 'underscore.string'
request = require 'superagent'

module.exports = React.createClass
  getInitialState: ->
    {
      query: @props.query.q || ""
      hits: []
      facets: []
    }

  componentDidMount: ->
    if @state.query isnt ""
      @search()

    @refs.query.getDOMNode().focus()

  render: ->
    <div className="search">
      <h1>Search</h1>
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
      .end (err, res) =>
        console.log res
        @setState {
          hits: res.body.hits.hits
          facets: res.body.facets.month.entries
          total: res.body.hits.total
          took: new Date() - searchStart
          searching: false
        }
