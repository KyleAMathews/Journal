{BrunchApplication, loadPostModel, clickHandler, scrollPosition, search, throbber} = require 'helpers'
{MainRouter} = require 'routers/main_router'
{MainView} = require 'views/main_view'
{PostsView} = require 'views/posts_view'
{Posts} = require 'collections/posts'
PostsCache = require 'collections/posts_cache'
Drafts = require 'collections/drafts'
DraftsIndicatorView = require 'views/drafts_indicator_view'
Search = require 'collections/search'

# Misc
require 'backbone_extensions'
require 'file_drop_handler'

class exports.Application extends BrunchApplication
  initialize: ->
    # Mixin Underscore.String functions.
    _.mixin(_.str.exports())

    @collections = {}
    @views = {}
    @util = {}
    @templates = {}
    @geolocation = require 'geolocation'

    @util.loadPostModel = loadPostModel
    @util.clickHandler = clickHandler
    @util.search = search
    @templates.throbber = throbber

    # Set defaults for marked.js (our markdown editor).
    marked.setOptions( smartLists: true )

    @site = new Backbone.Model

    @router = new MainRouter
    @eventBus = _.extend({}, Backbone.Events)

    @collections.posts = new Posts
    @collections.posts.load(true)
    @collections.postsCache = new PostsCache
    @collections.drafts = new Drafts
    @collections.drafts.fetch()
    @collections.search = new Search

    @views.main = new MainView el: $('#container')

    # Create and render our infinity.js postsView.
    postsView = new PostsView collection: app.collections.posts, el: $('#posts')
    postsView.render()

    @views.draftsIndicatorView = new DraftsIndicatorView(
      el: $('#menu-container .drafts')
      collection: @collections.drafts
    ).render()

    scrollPosition()
    $(window).on 'click', app.util.clickHandler

unless location.pathname is '/login'
  window.app = new exports.Application
