levelup = require 'level'
assign = require 'object-assign'
es = require('event-stream')
Promise = require 'bluebird'
fs = require 'fs'
_ = require 'underscore'
path = require 'path'
async = require 'async'
{
  graphql
  GraphQLSchema
  GraphQLObjectType
  GraphQLList
  GraphQLNonNull
  GraphQLString
  GraphQLInt
  GraphQLBoolean
  GraphQLID
} = require 'graphql'

{introspectionQuery, printSchema} = require 'graphql/utilities'

{
  connectionArgs,
  connectionDefinitions
  connectionFromArray,
  connectionFromPromisedArray,
  fromGlobalId,
  globalIdField,
  mutationWithClientMutationId,
  nodeDefinitions,
  cursorForObjectInConnection,
} = require 'graphql-relay'

getUser = (id) ->
  return {
    id: 1
    name: "Kyle"
  }

exports.register = (server, options, next) ->
  eventsDb = server.plugins.dbs.eventsDb
  postsByIdDb = server.plugins.dbs.postsByIdDb
  postsByLastUpdatedDb = server.plugins.dbs.postsByLastUpdatedDb
  postsByCreatedDB = server.plugins.dbs.postsByCreatedDB
  index = server.plugins.dbs.index

  loadPost = (id) ->
    new Promise((resolve, reject) ->
      postsByIdDb.get(id, (err, value) ->
        if err
          reject err
        else
          resolve value
      )
    )

  loadPosts = (args) ->
    reverse = true
    if args.last
      reverse = false
    new Promise((resolve, reject) ->
      filteredPosts = []
      postsByCreatedDB
        .createReadStream({
          reverse: reverse
        })
        .on('data', (data) ->
          post = data.value
          # Only return draft
          if args.draft and post.draft
            filteredPosts.push post
          else if not args.draft and not post.draft or post.deleted
            filteredPosts.push post
        )
        .on('end', ->
          resolve filteredPosts
        )
        .on('error', ->
          reject()
        )
    )

  # Define the node interface and field using the Relay helpers.
  idFetcher = (globalId, info) ->
    {type, id} = fromGlobalId(globalId)
    console.log "global node stuff", type, id
    switch type
      when "User"
        getUser(id)
      when "Post"
        new Promise((resolve, reject) ->
          postsByIdDb.get(id, (err, value) ->
            if err
              reject err
            else
              resolve value
          )
        )

  typeResolver = (obj) ->
    console.log "type resolver", obj
    if obj.name
      userType
    else
      postType

  {nodeInterface, nodeField} = nodeDefinitions(idFetcher, typeResolver)

  userType = new GraphQLObjectType({
    name: "User"
    description: "The logged-in user"
    fields: ->
      id: globalIdField('User')
      name:
        type: GraphQLString
        description: "The name of the user"
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
                  {},
                  connectionFromArray(hits, args),
                  {
                    total: hits.length
                    took: process.hrtime(start)[1] / 1000000
                  }
                )
          )
      post:
        type: postType
        description: "A post"
        args:
          post_id:
            type: GraphQLInt
        resolve: (root, args) ->
          console.log "post args", root, args
          new Promise((resolve, reject) ->
            postsByIdDb.get(args.post_id, (err, value) ->
              if err
                reject err
              else
                resolve value
            )
          )
      allPosts:
        type: postConnection
        description: "The user's posts"
        args: connectionArgs,
        resolve: (user, args) ->
          console.log "page args", args
          connectionFromPromisedArray(
            loadPosts(args),
            args
          )
      allDrafts:
        type: draftConnection
        description: "The user's draft posts"
        args: connectionArgs,
        resolve: (user, args) ->
          args.draft = true
          console.log "draft args", args
          connectionFromPromisedArray(
            loadPosts(args),
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
        type: new GraphQLNonNull(GraphQLInt)
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
      deleted:
        type: GraphQLBoolean
        description: "Is this post deleted?"
      draft:
        type: GraphQLBoolean
        description: "Is this post a draft?"
    args:
      post_id:
        type: GraphQLInt
        resolve: (post, args) ->
          console.log "post args", args
      id:
        type: GraphQLID
        resolve: (post, args) ->
          console.log post, args
          console.log "need to return something here..."
    interfaces: [nodeInterface]
  })

  # Define connection types
  {connectionType: postConnection, edgeType: postEdge} =
    connectionDefinitions({name: 'Post', nodeType: postType})

  {connectionType: draftConnection, edgeType: draftEdge} =
    connectionDefinitions({name: 'Draft', nodeType: postType})

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
          getUser(args.id)
  })


  # Mutations

  editPostMutation = mutationWithClientMutationId
    name: 'EditPost'
    inputFields:
      id:
        type: new GraphQLNonNull(GraphQLID)
      title:
        type: new GraphQLNonNull(GraphQLString)
      body:
        type: new GraphQLNonNull(GraphQLString)
      created_at:
        type: new GraphQLNonNull(GraphQLString)
    outputFields:
      post:
        type: postType
      viewer:
        type: userType
        resolve: ->
          getUser()
    mutateAndGetPayload: ({id, title, body, created_at}) ->
      updated_at = new Date().toJSON()

      new Promise (resolve, reject) ->
        console.log "editPost args", title,body
        {type, id} = fromGlobalId(id)
        console.log type, id

        # Load post
        postsByIdDb.get id, (err, post) ->
          updatedPost = _.extend(
            post,
            title: title,
            created_at: created_at,
            body: body,
            updated_at: updated_at
          )

          # Save event.
          eventsDb.put "#{post.id}__#{updated_at}__postUpdated", updatedPost,
            (err) ->
              if err then console.log err

          # Update dbs + search index.
          postsByIdDb.put updatedPost.id, updatedPost
          postsByCreatedDB.put(
            "#{updatedPost.created_at}-#{updatedPost.id}",
            updatedPost
          )

          # Update search index.
          unless updatedPost.draft
            index.update updatedPost

          resolve post: updatedPost

  savePostMutation = mutationWithClientMutationId
    name: 'SavePost'
    inputFields:
      id:
        type: new GraphQLNonNull(GraphQLID)
      title:
        type: new GraphQLNonNull(GraphQLString)
      body:
        type: new GraphQLNonNull(GraphQLString)
      created_at:
        type: new GraphQLNonNull(GraphQLString)
    outputFields:
      postId:
        type: GraphQLInt
        resolve: (post) ->
          post.id
      postEdge:
        type: postEdge
        resolve: (post) ->
          localId = post.id
          new Promise (resolve, reject) ->
            console.log "resolving postEdge", localId
            loadPost(localId).then (post) ->
              console.log "loaded post", post
              loadPosts().then (posts) ->
                console.log cursorForObjectInConnection(posts, post)
                console.log posts.indexOf(post)
                resolve {
                  # PR to export offsetToCursor as cursorForObjectInConnection
                  # only works w/ static array
                  cursor: new Buffer("arrayconnection:0", 'ascii').toString('base64')
                  node: post
                }
      post:
        type: postType
      viewer:
        type: userType
        resolve: ->
          console.log "viewer resolve"
          getUser()
    mutateAndGetPayload: ({id, title, body, created_at}) ->
      updated_at = new Date().toJSON()

      new Promise (resolve, reject) ->
        console.log "savePost args", title,body
        {type, id} = fromGlobalId(id)
        console.log type, id

        # Load post
        postsByIdDb.get id, (err, post) ->
          updatedPost = _.extend(
            post,
            title: title,
            body: body,
            created_at: created_at,
            updated_at: updated_at,
            draft: false
          )

          console.log updatedPost
          # Save event.
          eventsDb.put "#{post.id}__#{updated_at}__postUpdated", updatedPost,
            (err) ->
              if err then console.log err

          # Update dbs + search index.
          postsByIdDb.put updatedPost.id, updatedPost
          postsByCreatedDB.put(
            "#{updatedPost.created_at}-#{updatedPost.id}",
            updatedPost
          )

          # Update search index.
          index.update updatedPost

          resolve(
            postId: updatedPost.id
            post: updatedPost
          )

  createPostMutation = mutationWithClientMutationId
    name: 'CreatePost'
    inputFields:
      title:
        type: new GraphQLNonNull(GraphQLString)
      body:
        type: new GraphQLNonNull(GraphQLString)
      created_at:
        type: new GraphQLNonNull(GraphQLString)
    outputFields:
      draftEdge:
        type: draftEdge
        resolve: ({newLocalId}) ->
          new Promise (resolve, reject) ->
            console.log "resolving draftEdge", newLocalId
            loadPost(newLocalId).then (post) ->
              console.log "loaded post", post
              loadPosts(includeDrafts: true).then (posts) ->
                console.log cursorForObjectInConnection(posts, post)
                console.log posts.indexOf(post)
                resolve {
                  # PR to export offsetToCursor as cursorForObjectInConnection
                  # only works w/ static array
                  cursor: new Buffer("arrayconnection:0", 'ascii').toString('base64')
                  node: post
                }
      viewer:
        type: userType
        resolve: ->
          console.log "viewer resolve"
          getUser()
    mutateAndGetPayload: ({title, body, created_at}) ->
      new Promise (resolve, reject) ->
        console.log "createPost args", title, body, created_at

        newPost =
          title: title
          body: body
          created_at: created_at
          updated_at: created_at
          draft: true
          deleted: false
          starred: false

        console.log "newPost", newPost

        # Scan db to find next highest id.
        postsByIdDb.createValueStream()
          .pipe(es.writeArray (err, array) ->
            max = _.max(array, (post) -> post.id).id
            if max?
              newId = max + 1
            else
              newId = 1

            newPost.id = newId

            console.log "new id", newId

            # Save event.
            eventsDb.put "#{newPost.id}__#{newPost.created_at}__postCreated",
              newPost,
              (err) ->
                # Add to post indexes
                postsByIdDb.put newPost.id, newPost

                postsByCreatedDB.put(
                  "#{newPost.created_at}-#{newPost.id}",
                  newPost
                )

                console.log "returning from creating new post"
                resolve newLocalId: newPost.id
            )

  Mutation = new GraphQLObjectType({
    name: "Mutation"
    fields:
      editPost: editPostMutation
      createPost: createPostMutation
      savePost: savePostMutation
  })

  schema = new GraphQLSchema({
    query: queryType
    mutation: Mutation
  })

  # Write out schema to disk for Relay.
  graphql(schema, introspectionQuery)
    .then (result) ->
      fs.writeFileSync(
        path.join(__dirname, "../data/schema.json")
        JSON.stringify result, null, 2
      )
      console.log printSchema schema

  server.route
    method: ['get', 'post']
    path: "/graphql"
    config:
      handler: (request, reply) ->
        console.log "graphql query"
        console.log request.payload
        graphql(
          schema,
          request.payload.query,
          {},
          null,
          request.payload.variables,
          request.payload.operationName
        )
          .then((result) ->
            console.log 'result', result
            reply result
          )
          .catch((error) ->
            console.log error
          )

  next()

exports.register.attributes =
  name: 'GraphQL'
  version: '1.0.0'
