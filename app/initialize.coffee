{BrunchApplication, loadPost, clickHandler, scrollPosition} = require 'helpers'
{MainRouter} = require 'routers/main_router'
{MainView} = require 'views/main_view'
{PostsView} = require 'views/posts_view'
{Posts} = require 'collections/posts'
Drafts = require 'collections/drafts'

# Misc
require 'backbone_extensions'

class exports.Application extends BrunchApplication
  initialize: ->
    @collections = {}
    @views = {}
    @util = {}

    @site = new Backbone.Model

    @router = new MainRouter
    @eventBus = _.extend({}, Backbone.Events)

    @collections.posts = new Posts
    @collections.posts.fetch()
    @collections.drafts = new Drafts
    @collections.drafts.fetch()

    @views.main = new MainView el: $('#container')

    @util.loadPost = loadPost
    @util.clickHandler = clickHandler
    scrollPosition()
    $(window).on 'click', app.util.clickHandler

window.app = new exports.Application
