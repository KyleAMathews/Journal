module.exports = class Post extends Backbone.Model

  defaults:
    title: ''
    body: ''

  url: ->
    if @get('id')
      return "/posts/#{ @get('id') }"
    else if @get('nid')
      return "/posts/?nid=#{ @get 'nid' }"
    else
      @collection.url

  initialize: ->
    @on 'sync', ->
      if @get('body')? and @get('title')?
        @renderThings(true)
        app.collections.posts.cachePost(@)

  renderThings: (breakCache) ->
    if @get('rendered_body')? and @get('rendered_body') isnt "" and
      not breakCache
        return

    html = marked(@get('body'))
    @set { rendered_body: html }, silent: true
    @set { rendered_created: moment.utc(@get('created')).local().format("dddd, MMMM Do YYYY h:mma") }, silent: true

    # Created a shortened version of the post for postsView
    if @get('body').length > 300
      pieces = @get('body').split('\n')
      readMore = ""
      for piece in pieces
        readMore += piece + "\n"
        if readMore.length > 300
          break
      readMore = _.str.trim(readMore)

      # Add read more link unless our trimmed version ended up the same
      # as the original version.
      unless readMore.length is _.str.trim(@get('body')).length
        readMore += "\n\n[Read more](node/#{ @get('nid') })"

      @set { readMore: marked(readMore) }, silent: true
    else
      @set { readMore: marked(@get('body')) }, silent: true
