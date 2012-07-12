# BindTo facilitates the binding and unbinding of events
# from objects that extend `Backbone.Events`. It makes
# unbinding events, even with anonymous callback functions,
# easy.
#
# Thanks to Johnny Oshika for this code.
# http://stackoverflow.com/questions/7567404/backbone-js-repopulate-or-recreate-the-view/7607853#7607853
BindTo =
  # Store the event binding in array so it can be unbound
  # easily, at a later point in time.
  bindTo: (obj, eventName, callback, context) ->
    context = context || @
    obj.on(eventName, callback, context)

    if !@bindings then @bindings = []

    @bindings.push({
      obj: obj,
      eventName: eventName,
      callback: callback,
      context: context
    })

  # Unbind all of the events that we have stored.
  unbindAll: ->
    _.each(@bindings, (binding) ->
      binding.obj.off(null, null, binding.context)
    )

    this.bindings = []

_.extend(Backbone.Model.prototype, BindTo)
_.extend(Backbone.View.prototype, BindTo)
_.extend(Backbone.Collection.prototype, BindTo)

# Add close method to views that unbinds all views, removes it from the DOM
# and closes each of its children views.
Backbone.View.prototype.close = ->
  @unbind()
  @unbindAll()
  @remove()
  @closeChildrenViews()
  if @onClose then @onClose()

# Close children views. Also useful for cleaning up long-living views which creates
# lots of children views.
Backbone.View.prototype.closeChildrenViews = ->
  if @children
    _.each @children, (childView) ->
      if childView.close?
        childView.close()
    @children = []

# Add addChildView method so we can keep track of children views so when closing the
# parent view, it's easy to close each child view.
Backbone.View.prototype.addChildView = (childView) ->
  if !@children then @children = []
  @children.push childView
  return childView
