{BrunchApplication} = require 'helpers'
{MainRouter} = require 'routers/main_router'
{PostsView} = require 'views/posts_view'
{Posts} = require 'collections/posts'

class exports.Application extends BrunchApplication
  initialize: ->
    @router = new MainRouter
    @collections = {}
    @collections.posts = new Posts
    @collections.posts.fetch()
    @views = {}
    @views.posts = new PostsView collection: @collections.posts

window.app = new exports.Application
