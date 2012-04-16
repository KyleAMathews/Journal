{BrunchApplication, loadPost, clickHandler} = require 'helpers'
{MainRouter} = require 'routers/main_router'
{MainView} = require 'views/main_view'
{PostsView} = require 'views/posts_view'
{Posts} = require 'collections/posts'

class exports.Application extends BrunchApplication
  initialize: ->
    @collections = {}
    @views = {}
    @util = {}

    @router = new MainRouter
    @eventBus = _.extend({}, Backbone.Events)

    @collections.posts = new Posts
    @collections.posts.fetch()

    @views.main = new MainView el: $('#container')
    @views.posts = new PostsView collection: @collections.posts

    @util.loadPost = loadPost
    @util.clickHandler = clickHandler
    $(window).on 'click', app.util.clickHandler

window.app = new exports.Application
