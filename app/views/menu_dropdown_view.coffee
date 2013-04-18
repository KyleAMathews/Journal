module.exports = class MenuDropdownView extends Backbone.View

  events:
    'click li': 'clickLink'

  render: ->
    @$el.html "
      <li data-link='drafts'>Drafts (#{ app.collections.drafts.length })</li>
      <li data-link='logout'>Logout</li>
      "
    @

  clickLink: (e) ->
    link = $(e.currentTarget).data('link')
    if link is "logout"
      window.location = "/logout"
    else
      app.router.navigate "/#{ link }", true
