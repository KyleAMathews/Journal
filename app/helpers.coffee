class exports.BrunchApplication
  constructor: ->
    $ =>
      @initialize this
      Backbone.history.start({ pushState: true })

  initialize: ->
    null
