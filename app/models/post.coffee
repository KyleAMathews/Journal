module.exports = class Post extends Backbone.Model

  sync: Backbone.cachingSync(Backbone.sync, 'posts', null, true)

  defaults:
    title: ''
    body: ''
    created: new Date().toISOString()

  url: ->
    if @get('id')
      return "/posts/#{ @get('id') }"
    else if @get('nid')
      return "/posts/?nid=#{ @get 'nid' }"
    else
      @collection.url

  initialize: ->
    @on 'request', ->
      if @get('body')? and @get('title')?
        @renderThings()

  renderThings: ->
    # Eliminate the extra new line marked.js mostly adds.
    html = marked(@get('body'))
    @set rendered_body: html
    @set rendered_created: moment(@get('created')).format("dddd, MMMM Do YYYY")
