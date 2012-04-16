{RegionManager} = require 'mixins/region_manager'

class exports.MainView extends Backbone.View

# Add Mixins
exports.MainView.prototype = _.extend exports.MainView.prototype,
  RegionManager

