module.exports = React.createClass
  render: ->
    if @props.messages.length > 0
      messages = @props.messages.map (message) -> <p>{message}</p>
      return <div className={@props.type}>{messages}</div>
    else
      return <span />
