Code = require 'code'
Lab = require("lab")
lab = exports.lab = Lab.script()
Hapi = require 'hapi'
_ = require 'underscore'
config = require 'config'

it = lab.test
expect = Code.expect

newPost = 0

lab.experiment("posts plugin", ->
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
                done()

  it('successfully loads', (done) ->
    server.register([
      {
        register: require '../plugins/dbs'
      },
      {
        register: require '../plugins/posts'
      }
    ], (err) ->
      expect(err).to.equal(undefined)
      done()
    )
  )

  it("registers routes", (done) ->
    routes = server.table()

    expect(routes[0].table).to.have.length(5)
    expect(routes[0].table[0].path).to.equal("/posts")

    done()
  )

  it("lets you create new posts", (done) ->
    options =
      method: "POST"
      url: "/posts"
      payload:
        created_at: new Date().toJSON()
        title: "A test post"
        body: "A test body"

    server.inject options, (res) ->
      result = res.result
      expect(res.statusCode).to.equal(201)
      expect(result.id).to.exist()
      expect(result.created_at).to.exist()
      newPost = result.id
      done()
  )

  it("adds the new post to the event db", (done) ->
    eventsDb = server.plugins.dbs.eventsDb
    eventsDb
      .createKeyStream()
      .on 'data', (data) ->
        if newPost is parseInt(data.split('__')[0], 10)
          expect(newPost).to.equal(parseInt(data.split('__')[0], 10))
          done()
  )

  it("adds the new post to the posts id db", (done) ->
    postsByIdDb = server.plugins.dbs.postsByIdDb
    postsByIdDb
      .createKeyStream()
      .on 'data', (data) ->
        if newPost is parseInt(data, 10)
          expect(newPost).to.equal(parseInt(data, 10))
          done()
  )

  it("adds the new post to the posts updated_at db", (done) ->
    postsByLastUpdatedDb = server.plugins.dbs.postsByLastUpdatedDb
    postsByLastUpdatedDb
      .createReadStream({limit: 1})
      .on 'data', (data) ->
        expect(data.value.id).to.equal(newPost)
        done()
  )

  it("can get the newly created post", (done) ->
    options =
      method: "GET"
      url: "/posts/#{newPost}"

    server.inject options, (res) ->
      result = res.result
      expect(res.statusCode).to.equal(200)
      expect(result.id).to.exist()
      expect(result.created_at).to.exist()
      done()
  )

  it("can get all posts", (done) ->
    options =
      method: "GET"
      url: "/posts"

    server.inject options, (res) ->
      result = res.result
      expect(res.statusCode).to.equal(200)
      expect(result).to.be.instanceof(Array)
      expect(result[0].id).to.exist()
      expect(result[0].id).to.equal(newPost)
      expect(result[0].created_at).to.exist()
      done()
  )

  it("updates posts", (done) ->
    options =
      method: "PATCH"
      url: "/posts/#{newPost}"
      payload:
        title: "A test post 2"
        body: "A test body 2"


    server.inject options, (res) ->
      result = res.result
      expect(res.statusCode).to.equal(200)
      expect(result).to.be.instanceof(Object)
      expect(result.id).to.exist()
      expect(result.id).to.equal(newPost)
      expect(result.updated_at).to.exist()
      done()
  )

  it("saves event for update to the eventsdb", (done) ->
    eventsDb = server.plugins.dbs.eventsDb
    eventsDb
      .createReadStream({reverse: true, limit: 1})
      .on 'data', (data) ->
        if newPost is parseInt(data.key.split('__')[0], 10)
          expect(newPost).to.equal(parseInt(data.key.split('__')[0], 10))
          expect("postUpdated").to.equal(data.key.split('__')[2])
          expect("A test body 2").to.equal(data.value.body)
          done()
  )

  it("saves latest version to the posts id db", (done) ->
    postsByIdDb = server.plugins.dbs.postsByIdDb
    postsByIdDb
      .createReadStream()
      .on 'data', (data) ->
        if newPost is parseInt(data.key, 10)
          expect(newPost).to.equal(parseInt(data.key, 10))
          expect("A test body 2").to.equal(data.value.body)
          done()
  )

  it("saves latest version to the posts updated_at db", (done) ->
    postsByLastUpdatedDb = server.plugins.dbs.postsByLastUpdatedDb
    postsByLastUpdatedDb
      .createReadStream()
      .on 'data', (data) ->
        expect(data.value.id).to.equal(newPost)
        expect("A test body 2").to.equal(data.value.body)
        done()
  )

  it("delets posts", (done) ->
    options =
      method: "DELETE"
      url: "/posts/#{newPost}"

    server.inject options, (res) ->
      result = res.result
      expect(res.statusCode).to.equal(200)
      expect(result).to.be.instanceof(Object)
      expect(result.id).to.exist()
      expect(result.id).to.equal(newPost)
      expect(result.updated_at).to.exist()
      done()
  )

  it("saves event for delete to the eventsdb", (done) ->
    eventsDb = server.plugins.dbs.eventsDb
    eventsDb
      .createReadStream({reverse: true, limit: 1})
      .on 'data', (data) ->
        if newPost is parseInt(data.key.split('__')[0], 10)
          expect(newPost).to.equal(parseInt(data.key.split('__')[0], 10))
          expect("postDeleted").to.equal(data.key.split('__')[2])
          done()
  )

  it("removes post from the posts id db", (done) ->
    postsByIdDb = server.plugins.dbs.postsByIdDb
    postsByIdDb
      .createReadStream()
      .on 'data', (data) ->
        if newPost is parseInt(data.key, 10)
          expect(data).to.not.exist()
      .on 'end', ->
        done()
  )

  it("removes post from updated_at db", (done) ->
    postsByLastUpdatedDb = server.plugins.dbs.postsByLastUpdatedDb
    postsByLastUpdatedDb
      .createReadStream()
      .on 'data', (data) ->
        expect(data.value.id).to.not.equal(newPost)
      .on 'end', ->
        done()
  )
)
