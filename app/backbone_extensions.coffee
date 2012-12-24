# Add close method to views that unbinds all views, removes it from the DOM
# and closes each of its children views.
Backbone.View.prototype.close = ->
  @off()
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
