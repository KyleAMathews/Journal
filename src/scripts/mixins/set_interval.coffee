module.exports =
  componentWillMount: ->
    @intervals = []

  setInterval: ->
    @intervals.push(setInterval.apply(null, arguments))

  componentWillUnmount: ->
    @intervals.map(clearInterval)
