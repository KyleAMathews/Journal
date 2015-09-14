initialState = []

module.exports = (state = initialState, action) ->
  switch action.type
    when "FETCH_POSTS"
      return ['hi']
