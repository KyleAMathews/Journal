request = require 'superagent'

module.exports = React.createClass
  componentDidMount: ->
    console.log 'yo'
    request
      .get('/posts')
      .set('Accept', 'application/json')
      .end (err, res) ->
        console.log res.body

  render: ->
    <div>
      <h1>Hello World!</h1>
      <p>I mean, what else is there to worry about?</p>
    </div>
