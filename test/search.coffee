Code = require 'code'
Lab = require("lab")
lab = exports.lab = Lab.script()
Hapi = require 'hapi'
_ = require 'underscore'
config = require 'config'

it = lab.test
expect = Code.expect

index = null
newPost = 0

lab.experiment("search plugin", ->
  server = new Hapi.Server()
  server.connection()

  lab.after (done) ->
    eventsDb = server.plugins.dbs.eventsDb
    postsByIdDb = server.plugins.dbs.postsByIdDb
    postsByLastUpdatedDb = server.plugins.dbs.postsByLastUpdatedDb

    # Delete all test events.
    eventsDb
      .createKeyStream()
      .on 'data', (key) ->
        eventsDb.del(key)
      .on 'end', ->

        # Delete all postsByID objects.
        postsByIdDb
          .createKeyStream()
          .on 'data', (key) ->
            postsByIdDb.del(key)
          .on 'end', ->

            # Delete all postsByLastUpdatedDb objects.
            postsByLastUpdatedDb
              .createKeyStream()
              .on 'data', (key) ->
                postsByLastUpdatedDb.del(key)
              .on 'end', ->
                eventsDb.close()
                postsByIdDb.close()
                postsByLastUpdatedDb.close()
                server.stop({timeout: 0}, ->
                  done()
                )

  it('successfully loads', (done) ->
    server.register([
      {
        register: require '../plugins/dbs'
      },
      {
        register: require '../plugins/posts'
      },
      {
        register: require '../plugins/search'
      }
    ], (err) ->
      expect(err).to.equal(undefined)
      index = server.plugins.dbs.index
      done()
    )
  )

  it("adds new posts to search index", (done) ->
    options =
      method: "POST"
      url: "/posts"
      payload:
        created_at: new Date().toJSON()
        title: "A test post"
        body: "A test body"

    server.inject options, (res) ->
      result = res.result
      newPost = result.id
      expect(index.documentStore.get(result.id)).to.exist()
      done()
  )

  it("searches", (done) ->
    options =
      method: "GET"
      url: "/search?q=body"

    server.inject options, (res) ->
      result = res.result
      expect(result.hits[0].title).to.equal("A test post")
      expect(result.total).to.equal(1)
      expect(result.offset).to.equal(0)
      done()
  )

  it("handles searches with no results", (done) ->
    options =
      method: "GET"
      url: "/search?q=nothing"

    server.inject options, (res) ->
      result = res.result
      expect(result.total).to.equal(0)
      done()
  )

  it("updates search index when a post is updated", (done) ->
    options =
      method: "PATCH"
      url: "/posts/#{newPost}"
      payload:
        title: "exotic locations"
        body: "different altogether"


    server.inject options, (res) ->
      expect(index.documentStore.get(newPost).elements[0])
        .to.equal("altogeth")
      done()
  )

  it("deletes posts from index", (done) ->
    options =
      method: "DELETE"
      url: "/posts/#{newPost}"

    server.inject options, (res) ->
      result = res.result
      expect(index.documentStore.get(newPost)).to.not.exist()
      done()
  )
)
