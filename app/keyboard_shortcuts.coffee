$(document).on 'keydown', 'textarea, input', (e) ->
  if e.which is 27
    $(e.currentTarget).blur()
