levelup = require 'level'
assign = require 'object-assign'
Promise = require 'bluebird'
async = require 'async'
{
  graphql
  GraphQLSchema
  GraphQLObjectType
  GraphQLList
  GraphQLNonNull
  GraphQLString
  GraphQLInt
  GraphQLID
} = require 'graphql'

{
  connectionArgs,
  connectionDefinitions
  connectionFromArray,
  connectionFromPromisedArray,
  fromGlobalId,
  globalIdField,
  mutationWithClientMutationId,
  nodeDefinitions,
} = require 'graphql-relay'


exports.register = (server, options, next) ->
  postsByIdDb = server.plugins.dbs.postsByIdDb
  postsByLastUpdatedDb = server.plugins.dbs.postsByLastUpdatedDb
  postsByCreatedDB = server.plugins.dbs.postsByCreatedDB
  index = server.plugins.dbs.index

  # Define the node interface and field using the Relay helpers.
  {nodeInterface, nodeField} = nodeDefinitions(
    (globalId) ->
      {type, id} = fromGlobalId(globalId)
      switch type
        when "post"
          new Promise((resolve, reject) ->
            postsByIdDb.get(id, (err, value) ->
              if err
                reject err
              else
                resolve value
            )
          )
    ,
    (obj) ->
      console.log obj
      userType
  )


  userType = new GraphQLObjectType({
    name: "User"
    description: "The logged-in user"
    fields: ->
      id: globalIdField('User')
      name:
        type: GraphQLString
        description: "The name of the user"
        resolve: -> "Kyle Mathews"
      search:
        type: searchConnection
        description: "Search of the user's posts"
        args: assign(
          connectionArgs,
          {
            query:
              type: GraphQLString
          }
        )
        resolve: (user, args) ->
          start = process.hrtime()
          console.log "search args", args
          new Promise((resolve, reject) ->
            hits = index.search args.query

            # Hydrate
            async.map hits, ((hit, cb) ->
              postsByIdDb.get(hit.ref, (err, value) ->
                if err
                  return cb(err)
                else
                  cb(null, value)
              )
            ), (err, hits) ->
              if err
                reject err
              else
                resolve assign(
                  connectionFromArray(hits, args),
                  {
                    total: hits.length
                    took: process.hrtime(start)[1] / 1000000
                  }
                )
          )
      posts:
        type: postConnection
        description: "The user's posts"
        args: connectionArgs
        resolve: (user, args) ->
          console.log "page args", args
          postFetchPromise = new Promise((resolve, reject) ->
            filteredPosts = []
            if args.first
              limit = args.first
              reverse = true
            else if args.last
              limit = args.last
              reverse = false

            limit = limit + 1

            postsByCreatedDB
              .createReadStream({
                reverse: reverse
                limit: limit
              })
              .on('data', (data) ->
                if filteredPosts.length >= limit
                  return

                post = data.value
                unless post.deleted and post.draft
                  filteredPosts.push post
              )
              .on('end', ->
                resolve filteredPosts
              )
              .on('error', ->
                reject()
              )
          )
          connectionFromPromisedArray(
            postFetchPromise,
            args
          )
    interfaces: [nodeInterface]
  })

  ###
  # We define our post type.
  #
  # type Post {
  #   id: ID!
  #   title: String
  #   body: String
  #   created_at: String
  #   updated_at String
  #   deleted: Boolean
  #   starred: Boolean
  #   draft: Boolean
  #   latitude: String
  #   longitude: String
  # }
  ###
  postType = new GraphQLObjectType({
    name: 'Post'
    description: 'A journal post'
    fields: ->
      id: globalIdField('Post')
      post_id:
        type: new GraphQLNonNull(GraphQLString)
        description: "The id of this post"
        resolve: (post) -> post.id
      title:
        type: new GraphQLNonNull(GraphQLString)
        description: "The title of the post."
      body:
        type: new GraphQLNonNull(GraphQLString)
        description: "The body of the post."
      created_at:
        type: GraphQLString
        description: "The date the post was created (ISO 8601)."
      updated_at:
        type: GraphQLString
        description: "The date the post was last updated (ISO 8601)."
    args:
      id:
        type: GraphQLID
        resolve: (post, args) ->
          console.log post, args
          console.log "need to return something here..."
    interfaces: [nodeInterface]
  })

  # Define connection types
  {connectionType: postConnection} =
    connectionDefinitions({name: 'Post', nodeType: postType})

  {connectionType: searchConnection} =
    connectionDefinitions({
      name: 'Search',
      nodeType: postType
      connectionFields: ->
        total:
          type: GraphQLInt
        took:
          type: GraphQLInt
    })

  queryType = new GraphQLObjectType({
    name: 'Query'
    fields: ->
      node: nodeField
      viewer:
        type: userType
        resolve: (root, args) ->
          # TODO load this from a config file or if
          # we ever go multi-user, from the db.
          return { id: 1, name: "Kyle Mathews" }
  })

  schema = new GraphQLSchema({
    query: queryType
  })

  server.route
    method: ['get', 'post']
    path: "/graphql"
    config:
      handler: (request, reply) ->
        console.log "graphql query"
        console.log request.payload
        graphql(schema, request.payload.query)
          .then (result) ->
            reply result

  next()

exports.register.attributes =
  name: 'GraphQL'
  version: '1.0.0'
