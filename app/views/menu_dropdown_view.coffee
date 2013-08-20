module.exports = class MenuDropdownView extends Backbone.View

  initialize: ->
    $('html').on('click.menudropdownview', (e) =>
      if $(e.target).get(0) is $('.dropdown-menu').get(0) then return
      @close()
    )
    # Destroy popover when user presses escape.
    $(document).on "keydown.menudropdownview", (e) =>
      if e.keyCode is 27
        @close()

  events:
    'click li': 'clickLink'

  render: ->
    @$el.html "
      <li data-link='drafts'>Drafts (#{ app.collections.posts.getDrafts().length })</li>
      <li data-link='starred'>Starred</li>
      <li data-link='logout'>Logout</li>
      "
    @

  clickLink: (e) ->
    link = $(e.currentTarget).data('link')
    if link is "logout"
      window.location = "/logout"
    else
      app.router.navigate "/#{ link }", true

  onClose: ->
    $('html').off('.menudropdownview')
    $('document').off('.menudropdownview')
    @parent.dropdownView = null
