class exports.Post extends Backbone.Model

  sync: Backbone.cachingSync(Backbone.sync, 'posts', null, true)

  defaults:
    title: ''
    body: ''
    created: new Date().toISOString()

  initialize: ->
    @on 'request', ->
      @renderThings()

  renderThings: ->
    # Eliminate the extra new line marked.js mostly adds.
    html = marked(@get('body'))
    el = $('<div></div>')
    el.html(html)
    el.find('p').each( ->
      $(@).html($.trim($(@).html()))
    )
    @set rendered_body: el.html()
    @set rendered_created: moment(@get('created')).format("dddd, MMMM Do YYYY")
