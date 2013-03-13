# Check if a new cache is available on page load.
window.addEventListener('load', (e) ->

  window.applicationCache.addEventListener('updateready', (e) ->
    if (window.applicationCache.status == window.applicationCache.UPDATEREADY)
      # Browser downloaded a new app cache.
      # Swap it in and reload the page to get the new hotness.
      window.applicationCache.swapCache()
      $('body').append("<p class='alert-message'>A new version of the site is available, <a href='/'>reload now</a></p>")
      $(document).on 'click', -> window.location.reload()
  , false)
, false)
