$ = jQuery
expandingTextarea = require('widgets/expanding_textarea/expanding_textarea')

class exports.ExpandingTextareaView extends Backbone.View

  render: =>
    context = {}
    for k,v of @options
      context[k] = v
    @$el.html(expandingTextarea( context ))

    @makeAreaExpandable context.lines

    # Some css properties aren't set on the textareaClone right away,
    # presumably because the browser hasn't finished settting them yet.
    # Defer and then clone them.
    cloneCSSProperties = [
        'lineHeight', 'textDecoration', 'letterSpacing',
        'fontSize', 'fontFamily', 'fontStyle',
        'fontWeight', 'textTransform', 'textAlign',
        'direction', 'wordSpacing', 'fontSizeAdjust',
        'wordWrap',
        'borderLeftWidth', 'borderRightWidth',
        'borderTopWidth','borderBottomWidth',
        'paddingLeft', 'paddingRight',
        'paddingTop','paddingBottom',
        'marginLeft', 'marginRight',
        'marginTop','marginBottom',
        'boxSizing', 'webkitBoxSizing', 'mozBoxSizing', 'msBoxSizing'
    ]
    _.defer =>
      textarea = @$('textarea')
      pre = @$('pre')
      $.each cloneCSSProperties, (i, p) ->
        val = textarea.css(p)

        # Only set if different to prevent overriding percentage css values.
        if pre.css(p) isnt val
            pre.css(p, val)
    @

  makeAreaExpandable: (lines) =>
    @$('textarea').expandingTextarea()

    # Set minimum number of lines.
    _.defer =>
      if not lines? then lines = 1
      fontSize = parseInt(@$('textarea').css('font-size').slice(0,-2), 10)
      paddingTop = parseInt(@$('textarea').css('padding-top').slice(0,-2), 10)
      paddingBottom = parseInt(@$('textarea').css('padding-bottom').slice(0,-2), 10)
      # Mozilla bug - https://bugzilla.mozilla.org/show_bug.cgi?id=308801
      # min-height doesn't work right for box-sizing:border-box
      if $.browser.mozilla
        height = lines * 1.5
      else
        height = (lines * 1.5) + (paddingTop + paddingBottom) / fontSize # Num ems for padding.

      height = height + "em"
      @$('textarea').css({ 'min-height': height })
      @$('.textareaClone').css({ 'min-height': height })

      # Set widget to active.
      @$el.addClass('active')
      _.defer =>
        @$('textarea').trigger('input')
