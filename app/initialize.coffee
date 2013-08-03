{BrunchApplication, loadPostModel, clickHandler, scrollPosition, search, throbber} = require 'helpers'
{MainRouter} = require 'routers/main_router'
{MainView} = require 'views/main_view'
{PostsView} = require 'views/posts_view'
{Posts} = require 'collections/posts'
PostsCache = require 'collections/posts_cache'
Drafts = require 'collections/drafts'
MenuBarView = require 'views/menu_bar_view'
Search = require 'collections/search'
State = require 'models/state'

# Misc requires.
require 'backbone_extensions'
require 'file_drop_handler'
require 'alert_on_appcache_updates'

class exports.Application extends BrunchApplication
  initialize: ->
    # Mixin Underscore.String functions.
    _.mixin(_.str.exports())

    @eventBus = _.extend({}, Backbone.Events)
    @eventBus.on 'all', (eventName, args) -> console.log 'EBUS', eventName, args
    @collections = {}
    @models = {}
    @views = {}
    @util = {}
    @templates = {}
    @geolocation = require 'geolocation'
    @state = new State()

    @util.loadPostModel = loadPostModel
    @util.clickHandler = clickHandler
    @util.search = search
    @templates.throbber = throbber

    # Set defaults for marked.js (our markdown editor).
    marked.setOptions( smartLists: true )

    @site = new Backbone.Model

    @router = new MainRouter

    @collections.posts = new Posts
    @collections.posts.load(true)
    @collections.postsCache = new PostsCache
    @collections.drafts = new Drafts
    @collections.drafts.fetch()
    @collections.search = new Search


    new MenuBarView el: $('#menu-bar')

    @views.main = new MainView el: $('#container')

    # Create and render our infinity.js postsView.
    postsView = new PostsView collection: app.collections.posts, el: $('#posts')
    postsView.render()

    # Add fastclick.js to prevent 300 ms delay on click event on mobile browsers.
    FastClick.attach(document.body)

    scrollPosition()
    $(window).on 'click', app.util.clickHandler

unless location.pathname is '/login'
  window.app = new exports.Application

# Misc requires. Some depend on the app.eventBus being created hence the deferred.
_.defer ->
  require 'keyboard_shortcuts'
  require 'includes/online'
  require 'includes/offline_backbone_sync'
