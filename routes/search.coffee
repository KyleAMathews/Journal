config = require '../app_config'
redis = require 'redis'
rclient = redis.createClient(config.redis_url.port, config.redis_url.hostname, {auth_pass: config.redis_url.pass})
_ = require 'underscore'

recordQuery = (query, user) ->
  key = "query_#{ user }_#{ (Math.random() * 10000).toString().split('.')[0] }"
  rclient.set key, query
  # expire query data after one month.
  rclient.expire key, 2592000

exports.getIndex = (req, res) ->
  if req.isAuthenticated()
    if req.headers.accept? and req.headers.accept.indexOf('text/html') isnt -1
      res.render 'index'
  else
    res.redirect '/login'

exports.getQueries = (req, res) ->
  if req.isAuthenticated()
    if req.headers.accept? and req.headers.accept.indexOf('text/html') isnt -1
      res.render 'index'
    else
      # Fetch all queries stored by this person.
      rclient.keys("query_#{ req.user._id.toString() }_*", (err, keys) ->
        rclient.mget keys, (err, values) ->
          # Group common queries together and sort by count.
          processed = []
          if values?
            for value in values
              processed.push value.trim()
          results = _.groupBy(processed)
          set = []
          for query, number of results
            obj = {}
            obj[query] = number.length
            set.push(obj)
          set = _.sortBy set, (query) -> return _.values(query)[0]
          sortedSet = []
          for query in set
            sortedSet.push _.keys(query)[0]
          sortedSet = sortedSet.reverse()
          res.json sortedSet
      )

exports.makeQuery = (req, res) ->
  if req.isAuthenticated()
    if req.headers.accept? and req.headers.accept.indexOf('text/html') isnt -1
      res.render 'index'
    else
      Post = mongoose.model 'post'
      Post.search({
        from: 0
        size: 40
        query:
          query_string:
            fields: ['title', 'body'] # search the title and body of posts.
            default_operator: 'AND' # require all query terms to match
            query: req.params.query # The query from the REST call.
            use_dis_max: true
            fuzzy_prefix_length : 3
        filter:
          and: [
            {
              term:
                _user: req.user._id.toString()
            }
            #,
            #{
            #range:
              #created:
                #from: 1262304000000
                #to: 1293840000000
            #}
            ,
            {
              term:
                deleted: false
                draft: false
            }
          ]
        facets:
          year:
            date_histogram:
              field: 'created'
              interval: 'year'
          month:
            date_histogram:
              field: 'created'
              interval: 'month'
        highlight:
          fields:
            title: {"fragment_size" : 300}
            body: {"fragment_size" : 200}
      }, (err, posts) ->
        if err
          console.error err
          res.json 500, err
        else
          res.json posts
          # Record the query if there's a result.
          if posts?.hits.total > 0 and not err
            recordQuery(req.params.query, req.user._id.toString())
      )
  else
    res.redirect '/login'
