require('coffee-script/register')
Lab = require("lab")
Hapi = require 'hapi'

Lab.experiment("posts plugin", ->
  server = new Hapi.Server()
  Lab.test('plugin successfully loads', (done) ->
    server.pack.register({plugin: require '../plugins/posts'}, (err) ->
      Lab.expect(err).to.equal(undefined)
      done()
    )
  )
  Lab.test("Plugin registers routes", (done) ->
    table = server.table()

    Lab.expect(table).to.have.length(1)
    Lab.expect(table[0].path).to.equal("/posts")

    done()
  )
)
