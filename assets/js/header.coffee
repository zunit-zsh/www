###*
 * Contains methods for handling scroll events on the header
 *
 * @type {Header}
###
class Header
  ###*
   * Create the Header instance
   *
   * @return {Header}
  ###
  constructor: () ->
    @header = document.querySelector '.nav'
    @registerHeaderScrollingListener()
    @updateVersion()

  ###*
   * Register a listener which fires on scroll events
  ###
  registerHeaderScrollingListener: () ->
    window.addEventListener 'scroll', @fixHeaderOnScroll

  ###*
   * Fix the header to the top of the screen once the
   * scroll position reaches it
   *
   * @param  {Event} evt
  ###
  fixHeaderOnScroll: (evt) ->
    y = window.pageYOffset

    if y > 100
      document.body.classList.add 'scrolled'
    else
      document.body.classList.remove 'scrolled'

  updateVersion: () ->
    versionPlaceholder = document.querySelector '.nav--main-install-version'

    @getLatestRelease()
      .then (version) ->
        versionPlaceholder.innerHTML = version


  getLatestRelease: () ->
    new Promise (resolve, reject) ->
      # Get the updated at timestamp
      updatedAt = localStorage.getItem 'version_updated_at'
      timestamp = new Date().getTime()

      # If we are within the cache time, get and parse the
      # cached version number
      if (updatedAt + 300) > timestamp
        version = localStorage.getItem 'version'
        resolve version
        return

      # Fetch the list from the stored JSON file
      fetch 'https://api.github.com/repos/molovo/zunit/releases/latest'
        # Parse the JSON response
        .then (response) ->
          response.json()

        # Cache the version number
        .then (response) ->
          localStorage.setItem 'version', response.tag_name
          localStorage.setItem 'version_updated_at', timestamp
          resolve response.tag_name

        # Catch parsing errors
        .catch (err) ->
          reject err



module.exports = Header
