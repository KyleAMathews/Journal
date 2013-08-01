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

Backbone.Model.prototype.saveLocal = ->
  if @collection.burry?
    @collection.burry.set(@id, @toJSON())

#Backbone.Model.prototype._save = Backbone.Model.prototype.save
#Backbone.Model.prototype.save = ->
  #console.log 'doing the save yo'
  ## Don't need this variable anymore as we're syncing now and don't want to
  ## save it to the backend.
  #if @get('needsSynced')?
    #@unset('needsSynced')

  ## Do the normal save.
  #xhr = Backbone.Model.prototype._save.apply(this, arguments)
  #@saveLocal()

  #console.log xhr, @constructor.name
  ## Detect if the save failed due to being offline (status of 0) and set the
  ## app state to offline and save the model locally with the needsSynced
  ## flag and call the normal error/success functions.
  #xhr.fail (jqXHR, textStatus, errorThrown) =>
    #console.log jqXHR
    #if jqXHR.status is 0
      #app.eventBus.trigger 'online', false
      #@set 'needsSynced', true
      #console.log 'model state', @toJSON(), @constructor.name
      #@saveLocal()

#Backbone.Model.prototype._destroy = Backbone.Model.prototype.destroy
#Backbone.Model.prototype.destroy = ->
  #console.log 'doing the destroy yo'
  ## Do the normal destroy.
  #xhr = Backbone.Model.prototype._destroy.apply(this, arguments)
  #console.log 'destory xhr', xhr

  ## Detect if the destroy failed due to being offline (status of 0) and set the
  ## app state to offline and save the model locally with the needsDestroyed
  ## flag.
  ##unless xhr
    ##app.eventBus.trigger 'online', false
    ##@set 'needsDestroyed', true
    ##@saveLocal()

#Backbone.Model.prototype.initialize = ->
  #@listenTo app.state, 'change:online', (model, online) ->
    #console.log 'inside Model on change:online', @get('needsSynced'), online
    #if online
      #if @get('needsDestroyed')
        #console.log 'destorying a model!', @.toJSON(), @constructor.name
        #@destroy()
      #else if @get('needsSynced')
        #console.log 'saving model that needs synced', @get('title'), @constructor.name
        #@save()

