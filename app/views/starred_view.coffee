module.exports = class StarredView extends Backbone.View

  className: "starred-posts-page"

  initialize: ->
    @listenTo @collection, 'sync reset add', @render

  events:
    'click a': 'clickHandler'

  render: ->
    @$el.html("<h1>Starred Posts</h1><ul>")
    @addAll()
    @

  addAll: ->
    if @collection.length is 0
      return @$el.append "<p>Posts you star will show up here!</p>"
    grouped = @collection.groupBy (post) -> return moment(post.get('created')).local().format('YYYY-M')
    for week, group of grouped
      @$('ul').append("<h4>#{ moment(group[0].get('created')).local().format("MMMM YYYY") }</h4>")
      for post in group
        @$('ul').append("<li class='link'><a href='node/#{ post.get('nid') }'>#{ post.get 'title' } - <em>#{ moment(post.get('created')).local().format('MMMM D') }</em></a></li>")

  clickHandler: (e) ->
    e.preventDefault()
    href = $(e.currentTarget).attr('href')
    app.router.navigate(href, {trigger: true})
